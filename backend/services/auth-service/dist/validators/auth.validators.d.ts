import Joi from 'joi';
/**
 * Send OTP validation schema
 */
export declare const sendOTPSchema: Joi.ObjectSchema<any>;
/**
 * Verify OTP validation schema
 */
export declare const verifyOTPSchema: Joi.ObjectSchema<any>;
/**
 * Register customer validation schema
 */
export declare const registerCustomerSchema: Joi.ObjectSchema<any>;
/**
 * Register worker validation schema
 */
export declare const registerWorkerSchema: Joi.ObjectSchema<any>;
/**
 * Login validation schema
 * Accepts either phone or email as the identifier.
 */
export declare const loginSchema: Joi.ObjectSchema<any>;
/**
 * Refresh token validation schema
 */
export declare const refreshTokenSchema: Joi.ObjectSchema<any>;
/**
 * Reset password validation schema
 */
export declare const resetPasswordSchema: Joi.ObjectSchema<any>;
/**
 * Validation helper
 */
export declare const validate: <T>(schema: Joi.ObjectSchema, data: unknown) => {
    value: T;
    error?: Joi.ValidationError;
};
//# sourceMappingURL=auth.validators.d.ts.map