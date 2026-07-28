import mongoose, { Document, Schema, Model } from 'mongoose';
import { WITHDRAWAL_STATUS, WithdrawalStatus } from '../constants/index.js';
import { IBankDetails } from './Worker.js';

/**
 * Withdrawal Timeline Entry Interface
 */
export interface IWithdrawalTimelineEntry {
  status: WithdrawalStatus;
  timestamp: Date;
  note?: string;
  performedBy?: mongoose.Types.ObjectId;
}

/**
 * Withdrawal Document Interface
 */
export interface IWithdrawal extends Document {
  _id: mongoose.Types.ObjectId;
  worker: mongoose.Types.ObjectId;
  amount: number;
  // Bank details are snapshotted at request time (rather than read live off
  // Worker.bankDetails later) so a review always reflects what the worker
  // had on file when they asked for the payout, even if they edit their
  // profile afterwards.
  bankDetails: IBankDetails;
  status: WithdrawalStatus;
  adminNotes?: string;
  processedBy?: mongoose.Types.ObjectId;
  processedAt?: Date;
  timeline: IWithdrawalTimelineEntry[];
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Withdrawal Model Interface
 */
export interface IWithdrawalModel extends Model<IWithdrawal> {
  getPendingTotal(workerId: mongoose.Types.ObjectId | string): Promise<number>;
}

const withdrawalTimelineEntrySchema = new Schema<IWithdrawalTimelineEntry>(
  {
    status: {
      type: String,
      enum: WITHDRAWAL_STATUS,
      required: true,
    },
    timestamp: {
      type: Date,
      default: Date.now,
    },
    note: String,
    performedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
    },
  },
  { _id: false }
);

const withdrawalSchema = new Schema<IWithdrawal, IWithdrawalModel>(
  {
    worker: {
      type: Schema.Types.ObjectId,
      ref: 'Worker',
      required: true,
    },
    amount: {
      type: Number,
      required: [true, 'Withdrawal amount is required'],
      min: [1, 'Withdrawal amount must be greater than 0'],
    },
    bankDetails: {
      accountTitle: { type: String, required: true },
      accountNumber: { type: String, required: true },
      bankName: { type: String, required: true },
    },
    status: {
      type: String,
      enum: WITHDRAWAL_STATUS,
      default: 'PENDING',
    },
    adminNotes: {
      type: String,
      trim: true,
      maxlength: 500,
    },
    processedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
    },
    processedAt: Date,
    timeline: {
      type: [withdrawalTimelineEntrySchema],
      default: [],
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_doc, ret) => {
        const { __v, ...rest } = ret;
        return rest;
      },
    },
  }
);

withdrawalSchema.index({ worker: 1, createdAt: -1 });
withdrawalSchema.index({ status: 1, createdAt: -1 });

withdrawalSchema.pre('save', function (next) {
  if (this.isNew) {
    this.timeline.push({
      status: this.status,
      timestamp: new Date(),
      note: 'Withdrawal requested',
    });
  }
  next();
});

/**
 * Static: sum of amounts for a worker's requests still awaiting payout
 * (PENDING or APPROVED — APPROVED means admin signed off but the transfer
 * hasn't been marked PAID yet), used to compute the worker's available
 * balance so they can't request more than they actually have left.
 */
withdrawalSchema.statics.getPendingTotal = async function (
  workerId: mongoose.Types.ObjectId | string
): Promise<number> {
  const result = await this.aggregate([
    { $match: { worker: new mongoose.Types.ObjectId(workerId), status: { $in: ['PENDING', 'APPROVED'] } } },
    { $group: { _id: null, total: { $sum: '$amount' } } },
  ]);
  return result[0]?.total ?? 0;
};

export const Withdrawal = mongoose.model<IWithdrawal, IWithdrawalModel>('Withdrawal', withdrawalSchema);

export default Withdrawal;
