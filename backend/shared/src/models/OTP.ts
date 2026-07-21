import mongoose, { Document, Schema, Model } from 'mongoose';
import { OTP_PURPOSES, OTPPurpose, DEFAULTS } from '../constants/index.js';

/**
 * OTP Document Interface
 */
export interface IOTP extends Document {
  _id: mongoose.Types.ObjectId;
  phone: string;
  code: string;
  purpose: OTPPurpose;
  attempts: number;
  isUsed: boolean;
  expiresAt: Date;
  createdAt: Date;

  // Methods
  verify(code: string): boolean;
  markAsUsed(): Promise<IOTP>;
  incrementAttempts(): Promise<IOTP>;
}

/**
 * OTP Model Interface
 */
export interface IOTPModel extends Model<IOTP> {
  createOTP(phone: string, purpose: OTPPurpose): Promise<IOTP>;
  findValidOTP(phone: string, purpose: OTPPurpose): Promise<IOTP | null>;
  invalidateOTPs(phone: string, purpose: OTPPurpose): Promise<void>;
}

/**
 * OTP Schema
 */
const otpSchema = new Schema<IOTP, IOTPModel>(
  {
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
      trim: true,
    },
    code: {
      type: String,
      required: [true, 'OTP code is required'],
      length: [6, 'OTP must be 6 digits'],
    },
    purpose: {
      type: String,
      enum: OTP_PURPOSES,
      required: [true, 'OTP purpose is required'],
    },
    attempts: {
      type: Number,
      default: 0,
      max: [DEFAULTS.OTP_MAX_ATTEMPTS, 'Maximum OTP attempts exceeded'],
    },
    isUsed: {
      type: Boolean,
      default: false,
    },
    expiresAt: {
      type: Date,
      required: true,
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    toJSON: {
      transform: (_doc, ret) => {
        const { code, __v, ...rest } = ret; // Never expose OTP code in response
        return rest;
      },
    },
  }
);

// Indexes - Note: expiresAt has schema-level index, phone has schema-level index
otpSchema.index({ phone: 1, purpose: 1 });
// TTL index - automatically delete expired OTPs (using dedicated index instead of schema-level)
otpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

/**
 * Method to verify OTP code
 */
otpSchema.methods.verify = function (code: string): boolean {
  if (this.isUsed) {
    return false;
  }
  if (this.attempts >= DEFAULTS.OTP_MAX_ATTEMPTS) {
    return false;
  }
  if (new Date() > this.expiresAt) {
    return false;
  }
  return this.code === code;
};

/**
 * Method to mark OTP as used
 */
otpSchema.methods.markAsUsed = async function (): Promise<IOTP> {
  this.isUsed = true;
  return this.save();
};

/**
 * Method to increment attempts
 */
otpSchema.methods.incrementAttempts = async function (): Promise<IOTP> {
  this.attempts += 1;
  return this.save();
};

/**
 * Static method to create a new OTP
 */
otpSchema.statics.createOTP = async function (
  phone: string,
  purpose: OTPPurpose
): Promise<IOTP> {
  // Invalidate any existing OTPs for this phone and purpose
  await this.invalidateOTPs(phone, purpose);

  // Fixed dummy code — this project has no working SMS provider (Twilio
  // trial account, 5 messages/day, already exhausted) and isn't sending
  // real OTPs to real users, so every OTP is simply "123456" instead of
  // a randomly generated one. Not appropriate for a real deployment with
  // real users — swap back to crypto.randomInt(100000, 999999) if a real
  // SMS provider is ever wired up.
  const code = '123456';

  // Calculate expiry time
  const expiresAt = new Date();
  expiresAt.setMinutes(expiresAt.getMinutes() + DEFAULTS.OTP_EXPIRY_MINUTES);

  // Create and return new OTP
  return this.create({
    phone,
    code,
    purpose,
    expiresAt,
  });
};

/**
 * Static method to find valid OTP
 */
otpSchema.statics.findValidOTP = function (
  phone: string,
  purpose: OTPPurpose
): Promise<IOTP | null> {
  return this.findOne({
    phone,
    purpose,
    isUsed: false,
    attempts: { $lt: DEFAULTS.OTP_MAX_ATTEMPTS },
    expiresAt: { $gt: new Date() },
  });
};

/**
 * Static method to invalidate all OTPs for a phone and purpose
 */
otpSchema.statics.invalidateOTPs = async function (
  phone: string,
  purpose: OTPPurpose
): Promise<void> {
  await this.updateMany(
    { phone, purpose, isUsed: false },
    { isUsed: true }
  );
};

/**
 * OTP Model
 */
export const OTP = mongoose.model<IOTP, IOTPModel>('OTP', otpSchema);

export default OTP;
