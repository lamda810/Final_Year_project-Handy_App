import mongoose, { Document, Schema, Model } from 'mongoose';
import { SUPPORTED_LANGUAGES, SupportedLanguage } from '../constants/index.js';

/**
 * Address Interface
 */
export interface IAddress {
  _id?: mongoose.Types.ObjectId;
  label: string;
  address: string;
  city: string;
  coordinates?: {
    lat: number;
    lng: number;
  };
  isDefault: boolean;
}

/**
 * Customer Document Interface
 */
export interface ICustomer extends Document {
  _id: mongoose.Types.ObjectId;
  user: mongoose.Types.ObjectId;
  firstName: string;
  lastName: string;
  profileImage?: string;
  contactPhone?: string;
  addresses: IAddress[];
  preferredLanguage: SupportedLanguage;
  totalBookings: number;
  createdAt: Date;
  updatedAt: Date;

  // Virtuals
  fullName: string;
}

/**
 * Customer Model Interface
 */
export interface ICustomerModel extends Model<ICustomer> {
  findByUserId(userId: mongoose.Types.ObjectId | string): Promise<ICustomer | null>;
}

/**
 * Address Sub-Schema
 */
const addressSchema = new Schema<IAddress>(
  {
    label: {
      type: String,
      trim: true,
      maxlength: [50, 'Label cannot exceed 50 characters'],
      default: 'Home',
    },
    address: {
      type: String,
      required: [true, 'Address is required'],
      trim: true,
      maxlength: [500, 'Address cannot exceed 500 characters'],
    },
    city: {
      type: String,
      required: [true, 'City is required'],
      trim: true,
      maxlength: [100, 'City name cannot exceed 100 characters'],
    },
    coordinates: {
      lat: {
        type: Number,
        min: [-90, 'Latitude must be between -90 and 90'],
        max: [90, 'Latitude must be between -90 and 90'],
      },
      lng: {
        type: Number,
        min: [-180, 'Longitude must be between -180 and 180'],
        max: [180, 'Longitude must be between -180 and 180'],
      },
    },
    isDefault: {
      type: Boolean,
      default: false,
    },
  },
  { _id: true }
);

/**
 * Customer Schema
 */
const customerSchema = new Schema<ICustomer, ICustomerModel>(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User reference is required'],
      unique: true,
    },
    firstName: {
      type: String,
      required: [true, 'First name is required'],
      trim: true,
      maxlength: [50, 'First name cannot exceed 50 characters'],
    },
    lastName: {
      type: String,
      required: [true, 'Last name is required'],
      trim: true,
      maxlength: [50, 'Last name cannot exceed 50 characters'],
    },
    profileImage: {
      type: String,
      trim: true,
    },
    contactPhone: {
      type: String,
      trim: true,
      match: [/^(\+92|0)?3[0-9]{9}$/, 'Contact number must be a valid Pakistani mobile number'],
    },
    addresses: {
      type: [addressSchema],
      default: [],
      validate: {
        validator: function (addresses: IAddress[]) {
          return addresses.length <= 5;
        },
        message: 'Cannot have more than 5 saved addresses',
      },
    },
    preferredLanguage: {
      type: String,
      enum: SUPPORTED_LANGUAGES,
      default: 'en',
    },
    totalBookings: {
      type: Number,
      default: 0,
      min: [0, 'Total bookings cannot be negative'],
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_doc, ret) => {
        const { __v, ...rest } = ret;
        return rest;
      },
    },
    toObject: {
      virtuals: true,
    },
  }
);

// Indexes
customerSchema.index({ 'addresses.coordinates': '2dsphere' });

// Virtual for full name
customerSchema.virtual('fullName').get(function () {
  return `${this.firstName} ${this.lastName}`;
});

/**
 * Pre-save hook to ensure only one default address
 */
customerSchema.pre('save', function (next) {
  if (this.isModified('addresses')) {
    const defaultAddresses = this.addresses.filter(addr => addr.isDefault);

    // If more than one default, keep only the last one
    if (defaultAddresses.length > 1) {
      this.addresses.forEach((addr, index) => {
        if (index < this.addresses.length - 1) {
          addr.isDefault = false;
        }
      });
    }

    // If no default and addresses exist, make the first one default
    if (defaultAddresses.length === 0 && this.addresses.length > 0) {
      const firstAddress = this.addresses[0];
      if (firstAddress) {
        firstAddress.isDefault = true;
      }
    }
  }
  next();
});

/**
 * Static method to find customer by user ID
 */
customerSchema.statics.findByUserId = function (
  userId: mongoose.Types.ObjectId | string
): Promise<ICustomer | null> {
  return this.findOne({ user: userId }).populate('user', '-password');
};

/**
 * Customer Model
 */
export const Customer = mongoose.model<ICustomer, ICustomerModel>('Customer', customerSchema);

export default Customer;
