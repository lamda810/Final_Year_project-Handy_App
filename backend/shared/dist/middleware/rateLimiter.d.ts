/**
 * General API Rate Limiter
 * 100 requests per 15 minutes
 */
export declare const generalLimiter: import("express-rate-limit").RateLimitRequestHandler;
/**
 * Auth Endpoints Rate Limiter
 * 5 requests per minute (stricter for auth endpoints)
 */
export declare const authLimiter: import("express-rate-limit").RateLimitRequestHandler;
/**
 * OTP Request Rate Limiter
 * 3 OTP requests per hour in production; relaxed in development so local
 * testing/iteration isn't blocked by the same 1-hour cooldown.
 */
export declare const otpLimiter: import("express-rate-limit").RateLimitRequestHandler;
/**
 * Authenticated User Rate Limiter
 * 1000 requests per 15 minutes for authenticated users
 */
export declare const authenticatedLimiter: import("express-rate-limit").RateLimitRequestHandler;
/**
 * Heavy Operations Rate Limiter
 * 10 requests per minute (for file uploads, exports, etc.)
 */
export declare const heavyOperationLimiter: import("express-rate-limit").RateLimitRequestHandler;
/**
 * SOS Trigger Rate Limiter
 * 5 SOS triggers per hour (prevent abuse but allow genuine emergencies)
 */
export declare const sosLimiter: import("express-rate-limit").RateLimitRequestHandler;
//# sourceMappingURL=rateLimiter.d.ts.map