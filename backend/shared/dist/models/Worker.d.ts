import mongoose, { Document, Model } from 'mongoose';
import { ServiceCategory, WorkerVerificationStatus, DayOfWeek } from '../constants/index.js';
/**
 * Skill Interface
 */
export interface ISkill {
    category: ServiceCategory;
    experience: number;
    hourlyRate: number;
    isVerified: boolean;
}
/**
 * Schedule Interface
 */
export interface ISchedule {
    day: DayOfWeek;
    startTime: string;
    endTime: string;
}
/**
 * Bank Details Interface
 */
export interface IBankDetails {
    accountTitle: string;
    accountNumber: string;
    bankName: string;
}
/**
 * Document Interface (for worker documents like certificates)
 */
export interface IWorkerDocument {
    _id?: mongoose.Types.ObjectId;
    type: string;
    url: string;
    verified: boolean;
    uploadedAt: Date;
}
/**
 * GeoJSON Point Interface
 */
export interface IGeoPoint {
    type: 'Point';
    coordinates: [number, number];
}
/**
 * Worker Document Interface
 */
export interface IWorker extends Document {
    _id: mongoose.Types.ObjectId;
    user: mongoose.Types.ObjectId;
    firstName: string;
    lastName: string;
    profileImage?: string;
    contactPhone?: string;
    cnic: string;
    cnicVerified: boolean;
    cnicImages: {
        front?: string;
        back?: string;
    };
    skills: ISkill[];
    currentLocation?: IGeoPoint;
    serviceRadius: number;
    availability: {
        isAvailable: boolean;
        schedule: ISchedule[];
    };
    rating: {
        average: number;
        count: number;
    };
    trustScore: number;
    totalJobsCompleted: number;
    totalEarnings: number;
    bankDetails?: IBankDetails;
    documents: IWorkerDocument[];
    status: WorkerVerificationStatus;
    createdAt: Date;
    updatedAt: Date;
    fullName: string;
    updateLocation(lat: number, lng: number): Promise<IWorker>;
    updateRating(newRating: number): Promise<IWorker>;
}
/**
 * Worker Model Interface
 */
export interface IWorkerModel extends Model<IWorker> {
    findByUserId(userId: mongoose.Types.ObjectId | string): Promise<IWorker | null>;
    findByCNIC(cnic: string): Promise<IWorker | null>;
    findNearby(lat: number, lng: number, maxDistance: number, category?: ServiceCategory): Promise<IWorker[]>;
}
/**
 * Worker Model
 */
export declare const Worker: IWorkerModel;
export default Worker;
//# sourceMappingURL=Worker.d.ts.map