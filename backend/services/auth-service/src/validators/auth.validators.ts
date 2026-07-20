import Joi from 'joi';
import {
  phoneNumberSchema,
  emailSchema,
  passwordSchema,
  cnicSchema,
  otpSchema,
  OTP_PURPOSES,
  SERVICE_CATEGORIES,
} from '@handy-go/shared';

/**
 * Send OTP validation schema
 */
export const sendOTPSchema = Joi.object({
  phone: phoneNumberSchema.required(),
  purpose: Joi.string()
    .valid(...OTP_PURPOSES)
    .required()
    .messages({
      'any.only': 'Purpose must be one of: REGISTRATION, LOGIN, PASSWORD_RESET',
      'any.required': 'Purpose is required',
    }),
});

/**
 * Verify OTP validation schema
 */
export const verifyOTPSchema = Joi.object({
  phone: phoneNumberSchema.required(),
  code: otpSchema.required(),
  purpose: Joi.string()
    .valid(...OTP_PURPOSES)
    .required(),
});

/**
 * Register customer validation schema
 */
export const registerCustomerSchema = Joi.object({
  tempToken: Joi.string().required().messages({
    'any.required': 'Verification token is required',
  }),
  firstName: Joi.string().trim().min(2).max(50).required().messages({
    'string.min': 'First name must be at least 2 characters',
    'string.max': 'First name cannot exceed 50 characters',
    'any.required': 'First name is required',
  }),
  lastName: Joi.string().trim().min(2).max(50).required().messages({
    'string.min': 'Last name must be at least 2 characters',
    'string.max': 'Last name cannot exceed 50 characters',
    'any.required': 'Last name is required',
  }),
  email: emailSchema.optional(),
  password: passwordSchema.required(),
});

/**
 * Skill validation schema
 */
const skillItemSchema = Joi.object({
  category: Joi.string()
    .valid(...SERVICE_CATEGORIES)
    .required()
    .messages({
      'any.only': `Category must be one of: ${SERVICE_CATEGORIES.join(', ')}`,
    }),
  experience: Joi.number().integer().min(0).max(50).required(),
  hourlyRate: Joi.number().min(100).max(10000).required().messages({
    'number.min': 'Hourly rate must be at least 100 PKR',
    'number.max': 'Hourly rate cannot exceed 10000 PKR',
  }),
});

/**
 * Register worker validation schema
 */
export const registerWorkerSchema = Joi.object({
  tempToken: Joi.string().required().messages({
    'any.required': 'Verification token is required',
  }),
  firstName: Joi.string().trim().min(2).max(50).required(),
  lastName: Joi.string().trim().min(2).max(50).required(),
  email: emailSchema.optional(),
  password: passwordSchema.required(),
  cnic: cnicSchema.required(),
  skills: Joi.array().items(skillItemSchema).min(1).max(8).required().messages({
    'array.min': 'At least one skill is required',
    'array.max': 'Cannot have more than 8 skills',
  }),
});

/**
 * Login validation schema
 * Accepts either phone or email as the identifier.
 */
export const loginSchema = Joi.object({
  phone: phoneNumberSchema.optional(),
  email: emailSchema.optional(),
  password: Joi.string().required().messages({
    'any.required': 'Password is required',
  }),
})
  .or('phone', 'email')
  .messages({
    'object.missing': 'Phone or email is required',
  });

/**
 * Refresh token validation schema
 */
export const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required().messages({
    'any.required': 'Refresh token is required',
  }),
});

/**
 * Reset password validation schema
 */
export const resetPasswordSchema = Joi.object({
  tempToken: Joi.string().required(),
  newPassword: passwordSchema.required(),
});

/**
 * Validation helper
 */
export const validate = <T>(
  schema: Joi.ObjectSchema,
  data: unknown
): { value: T; error?: Joi.ValidationError } => {
  const { value, error } = schema.validate(data, {
    abortEarly: false,
    stripUnknown: true,
  });
  return { value: value as T, error };
};
