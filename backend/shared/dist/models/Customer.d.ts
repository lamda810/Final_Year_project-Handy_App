import mongoose, { Document, Model } from 'mongoose';
import { SupportedLanguage } from '../constants/index.js';
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
    fullName: string;
}
/**
 * Customer Model Interface
 */
export interface ICustomerModel extends Model<ICustomer> {
    findByUserId(userId: mongoose.Types.ObjectId | string): Promise<ICustomer | null>;
}
/**
 * Customer Model
 */
export declare const Customer: ICustomerModel;
export default Customer;
//# sourceMappingURL=Customer.d.ts.map