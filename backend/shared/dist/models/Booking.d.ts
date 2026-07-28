import mongoose, { Document, Model } from 'mongoose';
import { ServiceCategory, BookingStatus, PaymentStatus, PaymentMethod, CancellationParty } from '../constants/index.js';
/**
 * Timeline Entry Interface
 */
export interface ITimelineEntry {
    status: string;
    timestamp: Date;
    note?: string;
}
/**
 * Worker Location Entry Interface
 */
export interface IWorkerLocationEntry {
    coordinates: {
        lat: number;
        lng: number;
    };
    timestamp: Date;
}
/**
 * Booking Address Interface
 */
export interface IBookingAddress {
    full: string;
    city: string;
    coordinates: {
        lat: number;
        lng: number;
    };
}
/**
 * Pricing Interface
 */
export interface IPricing {
    estimatedPrice?: number;
    negotiatedPrice?: number;
    finalPrice?: number;
    laborCost?: number;
    materialsCost?: number;
    platformFee?: number;
    discount?: number;
}
/**
 * Payment Interface
 */
export interface IPayment {
    method: PaymentMethod;
    status: PaymentStatus;
    transactionId?: string;
}
/**
 * Rating Interface
 */
export interface IBookingRating {
    score: number;
    review?: string;
    createdAt: Date;
}
/**
 * Cancellation Interface
 */
export interface ICancellation {
    cancelledBy: CancellationParty;
    reason: string;
    timestamp: Date;
    fee?: number;
}
/**
 * Booking Document Interface
 */
export interface IBooking extends Document {
    _id: mongoose.Types.ObjectId;
    bookingNumber: string;
    customer: mongoose.Types.ObjectId;
    worker?: mongoose.Types.ObjectId;
    serviceCategory: ServiceCategory;
    problemDescription: string;
    aiDetectedServices: string[];
    address: IBookingAddress;
    scheduledDateTime: Date;
    isUrgent: boolean;
    status: BookingStatus;
    pricing: IPricing;
    estimatedDuration?: number;
    actualDuration?: number;
    actualStartTime?: Date;
    actualEndTime?: Date;
    timeline: ITimelineEntry[];
    workerLocation: IWorkerLocationEntry[];
    payment: IPayment;
    rating?: IBookingRating;
    images: {
        before: string[];
        after: string[];
    };
    cancellation?: ICancellation;
    createdAt: Date;
    updatedAt: Date;
    addTimelineEntry(status: string, note?: string): Promise<IBooking>;
    updateWorkerLocation(lat: number, lng: number): Promise<IBooking>;
}
/**
 * Booking Model Interface
 */
export interface IBookingModel extends Model<IBooking> {
    generateBookingNumber(): Promise<string>;
    findByBookingNumber(bookingNumber: string): Promise<IBooking | null>;
}
/**
 * Booking Model
 */
export declare const Booking: IBookingModel;
export default Booking;
//# sourceMappingURL=Booking.d.ts.map