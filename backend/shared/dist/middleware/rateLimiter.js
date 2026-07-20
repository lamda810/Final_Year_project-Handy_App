import rateLimit from 'express-rate-limit';
import { HTTP_STATUS } from '../constants/index.js';
/**
 * General API Rate Limiter
 * 100 requests per 15 minutes
 */
export const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100,
    message: {
        success: false,
        message: 'Too many requests, please try again after 15 minutes',
        errorCode: 'RATE_LIMIT_EXCEEDED',
    },
    statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: req => {
        // Use user ID if authenticated, otherwise use IP
        return req.user?.id || req.ip || 'anonymous';
    },
});
/**
 * Auth Endpoints Rate Limiter
 * 5 requests per minute (stricter for auth endpoints)
 */
export const authLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 5,
    message: {
        success: false,
        message: 'Too many authentication attempts, please try again after 1 minute',
        errorCode: 'RATE_LIMIT_EXCEEDED',
    },
    statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
    standardHeaders: true,
    legacyHeaders: false,
    skipFailedRequests: false,
});
/**
 * OTP Request Rate Limiter
 * 3 OTP requests per hour in production; relaxed in development so local
 * testing/iteration isn't blocked by the same 1-hour cooldown.
 */
export const otpLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: process.env.NODE_ENV === 'production' ? 3 : 100,
    message: {
        success: false,
        message: 'Too many OTP requests, please try again after 1 hour',
        errorCode: 'OTP_RATE_LIMIT_EXCEEDED',
    },
    statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: req => {
        // Use phone number if available, otherwise IP
        return req.body?.phone || req.ip || 'anonymous';
    },
});
/**
 * Authenticated User Rate Limiter
 * 1000 requests per 15 minutes for authenticated users
 */
export const authenticatedLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 1000,
    message: {
        success: false,
        message: 'Too many requests, please try again after 15 minutes',
        errorCode: 'RATE_LIMIT_EXCEEDED',
    },
    statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: req => {
        return req.user?.id || req.ip || 'anonymous';
    },
    skip: req => {
        // Skip rate limiting if user is not authenticated (let other limiters handle it)
        return !req.user;
    },
});
/**
 * Heavy Operations Rate Limiter
 * 10 requests per minute (for file uploads, exports, etc.)
 */
export const heavyOperationLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 10,
    message: {
        success: false,
        message: 'Too many requests for this operation, please try again after 1 minute',
        errorCode: 'RATE_LIMIT_EXCEEDED',
    },
    statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
    standardHeaders: true,
    legacyHeaders: false,
});
/**
 * SOS Trigger Rate Limiter
 * 5 SOS triggers per hour (prevent abuse but allow genuine emergencies)
 */
export const sosLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 5,
    message: {
        success: false,
        message: 'Too many SOS triggers, please contact support if you have a genuine emergency',
        errorCode: 'SOS_RATE_LIMIT_EXCEEDED',
    },
    statusCode: HTTP_STATUS.TOO_MANY_REQUESTS,
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: req => {
        return req.user?.id || req.ip || 'anonymous';
    },
});
//# sourceMappingURL=rateLimiter.js.map