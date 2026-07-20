import mongoose, { Document, Schema } from 'mongoose';

export type ChatSenderType = 'CUSTOMER' | 'WORKER';

export interface IChatMessage extends Document {
  booking: mongoose.Types.ObjectId;
  sender: mongoose.Types.ObjectId;
  senderType: ChatSenderType;
  message: string;
  createdAt: Date;
  updatedAt: Date;
}

const chatMessageSchema = new Schema<IChatMessage>(
  {
    booking: {
      type: Schema.Types.ObjectId,
      ref: 'Booking',
      required: true,
      index: true,
    },
    sender: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    senderType: {
      type: String,
      enum: ['CUSTOMER', 'WORKER'],
      required: true,
    },
    message: {
      type: String,
      required: true,
      trim: true,
      maxlength: 2000,
    },
  },
  { timestamps: true }
);

chatMessageSchema.index({ booking: 1, createdAt: 1 });

export const ChatMessage = mongoose.model<IChatMessage>('ChatMessage', chatMessageSchema);
