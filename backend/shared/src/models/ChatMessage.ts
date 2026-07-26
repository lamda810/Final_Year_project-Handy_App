import mongoose, { Document, Schema } from 'mongoose';

export type ChatSenderType = 'CUSTOMER' | 'WORKER';

// TEXT is a normal chat bubble. PRICE_OFFER is a proposed price from either
// party awaiting a response. PRICE_COUNTER is a new amount proposed in
// response to a prior offer (still awaiting a response, same as an offer).
// PRICE_ACCEPTED/PRICE_REJECTED are system-authored notices recording the
// resolution of the offer they reference via offerRef.
export type ChatMessageType =
  | 'TEXT'
  | 'PRICE_OFFER'
  | 'PRICE_COUNTER'
  | 'PRICE_ACCEPTED'
  | 'PRICE_REJECTED';

export type OfferStatus = 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'SUPERSEDED';

export interface IChatMessage extends Document {
  booking: mongoose.Types.ObjectId;
  sender: mongoose.Types.ObjectId;
  senderType: ChatSenderType;
  message: string;
  messageType: ChatMessageType;
  offerAmount?: number;
  offerStatus?: OfferStatus;
  offerRef?: mongoose.Types.ObjectId;
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
    messageType: {
      type: String,
      enum: ['TEXT', 'PRICE_OFFER', 'PRICE_COUNTER', 'PRICE_ACCEPTED', 'PRICE_REJECTED'],
      default: 'TEXT',
    },
    offerAmount: Number,
    offerStatus: {
      type: String,
      enum: ['PENDING', 'ACCEPTED', 'REJECTED', 'SUPERSEDED'],
    },
    offerRef: {
      type: Schema.Types.ObjectId,
      ref: 'ChatMessage',
    },
  },
  { timestamps: true }
);

chatMessageSchema.index({ booking: 1, createdAt: 1 });

export const ChatMessage = mongoose.model<IChatMessage>('ChatMessage', chatMessageSchema);
