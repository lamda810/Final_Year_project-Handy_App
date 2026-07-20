import Joi from 'joi';
import { SERVICE_CATEGORIES } from '@handy-go/shared';
export const createBookingSchema = Joi.object({
    serviceCategory: Joi.string()
        .valid(...SERVICE_CATEGORIES)
        .required(),
    problemDescription: Joi.string().min(10).max(1000).required().trim(),
    address: Joi.object({
        full: Joi.string().min(5).max(200).required().trim(),
        city: Joi.string().min(2).max(50).required().trim(),
        coordinates: Joi.object({
            lat: Joi.number().min(-90).max(90).required(),
            lng: Joi.number().min(-180).max(180).required(),
        }).required(),
    }).required(),
    scheduledDateTime: Joi.date().iso().min('now').required(),
    isUrgent: Joi.boolean().default(false),
    images: Joi.array().items(Joi.string().uri()).max(5),
});
export const selectWorkerSchema = Joi.object({
    workerId: Joi.string().hex().length(24).required(),
});
export const cancelBookingSchema = Joi.object({
    reason: Joi.string().min(5).max(500).required().trim(),
});
export const rateBookingSchema = Joi.object({
    rating: Joi.number().min(1).max(5).required(),
    review: Joi.string().max(500).trim(),
    categories: Joi.object({
        punctuality: Joi.number().min(1).max(5),
        quality: Joi.number().min(1).max(5),
        professionalism: Joi.number().min(1).max(5),
        value: Joi.number().min(1).max(5),
    }),
});
export const acceptBookingSchema = Joi.object({
    estimatedArrivalMinutes: Joi.number().min(5).max(180),
});
export const rejectBookingSchema = Joi.object({
    reason: Joi.string().min(5).max(500).required().trim(),
});
export const startJobSchema = Joi.object({
    beforeImages: Joi.array().items(Joi.string().uri()).max(5),
});
export const completeJobSchema = Joi.object({
    afterImages: Joi.array().items(Joi.string().uri()).max(5),
    // Optional now — the price is decided at booking creation and the
    // worker no longer re-enters it; the controller falls back to
    // booking.pricing.estimatedPrice when this is omitted.
    finalPrice: Joi.number().min(0),
    materialsCost: Joi.number().min(0).default(0),
    notes: Joi.string().max(500).trim(),
});
export const updateLocationSchema = Joi.object({
    coordinates: Joi.object({
        lat: Joi.number().min(-90).max(90).required(),
        lng: Joi.number().min(-180).max(180).required(),
    }).required(),
});
export const adminUpdateBookingSchema = Joi.object({
    status: Joi.string().valid('PENDING', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'DISPUTED'),
    notes: Joi.string().max(1000).trim(),
});
export const adminQuerySchema = Joi.object({
    status: Joi.string().valid('PENDING', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'DISPUTED'),
    serviceCategory: Joi.string().valid(...SERVICE_CATEGORIES),
    startDate: Joi.date().iso(),
    endDate: Joi.date().iso().min(Joi.ref('startDate')),
    page: Joi.number().min(1).default(1),
    limit: Joi.number().min(1).max(100).default(20),
});
export const sendMessageSchema = Joi.object({
    message: Joi.string().min(1).max(2000).required().trim(),
});
//# sourceMappingURL=booking.validators.js.map