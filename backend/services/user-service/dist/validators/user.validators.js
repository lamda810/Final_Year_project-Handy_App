import Joi from 'joi';
// Separate from the login phone (which is immutable) — an optional
// alternate number customers/workers can give out for calls.
const contactPhoneSchema = Joi.string()
    .pattern(/^(\+92|0)?3[0-9]{9}$/)
    .allow('')
    .messages({
    'string.pattern.base': 'Contact number must be a valid Pakistani mobile number (e.g., +923001234567 or 03001234567)',
});
export const updateCustomerProfileSchema = Joi.object({
    firstName: Joi.string().min(2).max(50).trim(),
    lastName: Joi.string().min(2).max(50).trim(),
    email: Joi.string().email().lowercase().trim(),
    profileImage: Joi.string().uri().trim(),
    contactPhone: contactPhoneSchema,
    preferredLanguage: Joi.string().valid('en', 'ur'),
});
export const addAddressSchema = Joi.object({
    label: Joi.string().max(50).trim().default('Home'),
    address: Joi.string().min(5).max(200).required().trim(),
    city: Joi.string().min(2).max(50).required().trim(),
    coordinates: Joi.object({
        lat: Joi.number().min(-90).max(90).required(),
        lng: Joi.number().min(-180).max(180).required(),
    }),
    isDefault: Joi.boolean().default(false),
});
export const updateAddressSchema = Joi.object({
    label: Joi.string().max(50).trim(),
    address: Joi.string().min(5).max(200).trim(),
    city: Joi.string().min(2).max(50).trim(),
    coordinates: Joi.object({
        lat: Joi.number().min(-90).max(90).required(),
        lng: Joi.number().min(-180).max(180).required(),
    }),
    isDefault: Joi.boolean(),
}).min(1);
export const updateWorkerProfileSchema = Joi.object({
    firstName: Joi.string().min(2).max(50).trim(),
    lastName: Joi.string().min(2).max(50).trim(),
    email: Joi.string().email().lowercase().trim(),
    profileImage: Joi.string().uri().trim(),
    contactPhone: contactPhoneSchema,
    skills: Joi.array().items(Joi.object({
        category: Joi.string().valid('PLUMBING', 'ELECTRICAL', 'CLEANING', 'AC_REPAIR', 'CARPENTER', 'PAINTING', 'MECHANIC', 'GENERAL_HANDYMAN').required(),
        experience: Joi.number().min(0).max(50).required(),
        hourlyRate: Joi.number().min(100).max(10000).required(),
    })).min(1),
    serviceRadius: Joi.number().min(1).max(50),
    availability: Joi.object({
        isAvailable: Joi.boolean(),
        schedule: Joi.array().items(Joi.object({
            day: Joi.string().valid('MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN').required(),
            startTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).required(),
            endTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).required(),
        })),
    }),
    bankDetails: Joi.object({
        accountTitle: Joi.string().min(3).max(100).trim(),
        accountNumber: Joi.string().min(10).max(30).trim(),
        bankName: Joi.string().min(3).max(100).trim(),
    }),
});
export const updateLocationSchema = Joi.object({
    coordinates: Joi.object({
        lat: Joi.number().min(-90).max(90).required(),
        lng: Joi.number().min(-180).max(180).required(),
    }).required(),
});
export const updateAvailabilitySchema = Joi.object({
    isAvailable: Joi.boolean().required(),
});
export const addDocumentSchema = Joi.object({
    type: Joi.string().min(2).max(50).required().trim(),
    url: Joi.string().uri().required().trim(),
});
export const verifyWorkerSchema = Joi.object({
    status: Joi.string().valid('ACTIVE', 'REJECTED').required(),
    notes: Joi.string().max(500).trim(),
});
export const updateUserStatusSchema = Joi.object({
    isActive: Joi.boolean().required(),
    reason: Joi.string().max(500).trim(),
});
//# sourceMappingURL=user.validators.js.map