import mongoose, { Schema } from 'mongoose';
import { SERVICE_CATEGORIES, BOOKING_STATUS, PAYMENT_STATUS, PAYMENT_METHODS, CANCELLATION_PARTIES, } from '../constants/index.js';
/**
 * Timeline Entry Sub-Schema
 */
const timelineEntrySchema = new Schema({
    status: {
        type: String,
        required: true,
    },
    timestamp: {
        type: Date,
        default: Date.now,
    },
    note: String,
}, { _id: false });
/**
 * Worker Location Entry Sub-Schema
 */
const workerLocationEntrySchema = new Schema({
    coordinates: {
        lat: { type: Number, required: true },
        lng: { type: Number, required: true },
    },
    timestamp: {
        type: Date,
        default: Date.now,
    },
}, { _id: false });
/**
 * Booking Schema
 */
const bookingSchema = new Schema({
    bookingNumber: {
        type: String,
        unique: true,
    },
    customer: {
        type: Schema.Types.ObjectId,
        ref: 'Customer',
        required: [true, 'Customer is required'],
    },
    worker: {
        type: Schema.Types.ObjectId,
        ref: 'Worker',
    },
    serviceCategory: {
        type: String,
        enum: SERVICE_CATEGORIES,
        required: [true, 'Service category is required'],
    },
    problemDescription: {
        type: String,
        required: [true, 'Problem description is required'],
        trim: true,
        maxlength: [1000, 'Problem description cannot exceed 1000 characters'],
    },
    aiDetectedServices: {
        type: [String],
        default: [],
    },
    address: {
        full: {
            type: String,
            required: [true, 'Full address is required'],
            trim: true,
        },
        city: {
            type: String,
            required: [true, 'City is required'],
            trim: true,
        },
        coordinates: {
            lat: {
                type: Number,
                required: [true, 'Latitude is required'],
            },
            lng: {
                type: Number,
                required: [true, 'Longitude is required'],
            },
        },
    },
    scheduledDateTime: {
        type: Date,
        required: [true, 'Scheduled date/time is required'],
    },
    isUrgent: {
        type: Boolean,
        default: false,
    },
    status: {
        type: String,
        enum: BOOKING_STATUS,
        default: 'PENDING',
    },
    pricing: {
        estimatedPrice: Number,
        finalPrice: Number,
        laborCost: Number,
        materialsCost: Number,
        platformFee: Number,
        discount: Number,
    },
    estimatedDuration: Number,
    actualDuration: Number,
    actualStartTime: Date,
    actualEndTime: Date,
    timeline: {
        type: [timelineEntrySchema],
        default: [],
    },
    workerLocation: {
        type: [workerLocationEntrySchema],
        default: [],
    },
    payment: {
        method: {
            type: String,
            enum: PAYMENT_METHODS,
            default: 'CASH',
        },
        status: {
            type: String,
            enum: PAYMENT_STATUS,
            default: 'PENDING',
        },
        transactionId: String,
    },
    rating: {
        score: {
            type: Number,
            min: [1, 'Rating must be between 1 and 5'],
            max: [5, 'Rating must be between 1 and 5'],
        },
        review: {
            type: String,
            maxlength: [500, 'Review cannot exceed 500 characters'],
        },
        createdAt: Date,
    },
    images: {
        before: {
            type: [String],
            default: [],
        },
        after: {
            type: [String],
            default: [],
        },
    },
    cancellation: {
        cancelledBy: {
            type: String,
            enum: CANCELLATION_PARTIES,
        },
        reason: String,
        timestamp: Date,
        fee: Number,
    },
}, {
    timestamps: true,
    toJSON: {
        transform: (_doc, ret) => {
            const { __v, ...rest } = ret;
            return rest;
        },
    },
});
// Indexes
bookingSchema.index({ customer: 1, createdAt: -1 });
bookingSchema.index({ worker: 1, createdAt: -1 });
bookingSchema.index({ status: 1 });
bookingSchema.index({ serviceCategory: 1, status: 1 });
bookingSchema.index({ scheduledDateTime: 1 });
// Note: no 2dsphere index on address.coordinates — that field is a plain
// { lat, lng } object (not GeoJSON), and nothing in the codebase ever
// geo-queries a booking's own address. A 2dsphere index here can't extract
// valid geo keys from this shape and makes every insert fail once MongoDB
// actually enforces it. Geospatial matching happens against
// Worker.currentLocation (real GeoJSON Point) instead.
/**
 * Pre-save hook to generate booking number and update timeline
 */
bookingSchema.pre('save', async function (next) {
    // Generate booking number if new document
    if (this.isNew && !this.bookingNumber) {
        this.bookingNumber = await this.constructor.generateBookingNumber();
        // Add initial timeline entry
        this.timeline.push({
            status: 'PENDING',
            timestamp: new Date(),
            note: 'Booking created',
        });
    }
    // Note: every controller that changes `status` already pushes its own
    // descriptive timeline entry (with a note) alongside the assignment, so
    // this hook must not also push one — that produced a duplicate, note-less
    // entry for every single status transition.
    next();
});
/**
 * Static method to generate booking number
 * Format: HG-YYYYMMDD-XXXXX (e.g., HG-20240115-00001)
 */
bookingSchema.statics.generateBookingNumber = async function () {
    const today = new Date();
    const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '');
    const prefix = `HG-${dateStr}-`;
    // Find the last booking number for today
    const lastBooking = await this.findOne({
        bookingNumber: { $regex: `^${prefix}` },
    })
        .sort({ bookingNumber: -1 })
        .select('bookingNumber');
    let sequence = 1;
    if (lastBooking?.bookingNumber) {
        const lastSequence = parseInt(lastBooking.bookingNumber.slice(-5), 10);
        sequence = lastSequence + 1;
    }
    return `${prefix}${sequence.toString().padStart(5, '0')}`;
};
/**
 * Static method to find by booking number
 */
bookingSchema.statics.findByBookingNumber = function (bookingNumber) {
    return this.findOne({ bookingNumber })
        .populate('customer')
        .populate('worker');
};
/**
 * Method to add timeline entry
 */
bookingSchema.methods.addTimelineEntry = async function (status, note) {
    this.timeline.push({
        status,
        timestamp: new Date(),
        note,
    });
    return this.save();
};
/**
 * Method to update worker location
 */
bookingSchema.methods.updateWorkerLocation = async function (lat, lng) {
    this.workerLocation.push({
        coordinates: { lat, lng },
        timestamp: new Date(),
    });
    // Keep only last 100 location entries
    if (this.workerLocation.length > 100) {
        this.workerLocation = this.workerLocation.slice(-100);
    }
    return this.save();
};
/**
 * Booking Model
 */
export const Booking = mongoose.model('Booking', bookingSchema);
export default Booking;
//# sourceMappingURL=Booking.js.map