import { Request, Response, NextFunction } from 'express';
/**
 * Send OTP
 * POST /api/auth/send-otp
 */
export declare const sendOTP: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Verify OTP
 * POST /api/auth/verify-otp
 */
export declare const verifyOTP: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Register Customer
 * POST /api/auth/register/customer
 */
export declare const registerCustomer: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Register Worker
 * POST /api/auth/register/worker
 */
export declare const registerWorker: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Login
 * POST /api/auth/login
 */
export declare const login: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Refresh Token
 * POST /api/auth/refresh-token
 */
export declare const refreshToken: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Forgot Password - sends OTP
 * POST /api/auth/forgot-password
 */
export declare const forgotPassword: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Reset Password
 * POST /api/auth/reset-password
 */
export declare const resetPassword: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Logout - revoke current tokens
 * POST /api/auth/logout
 */
export declare const logout: (req: Request, res: Response, next: NextFunction) => void;
//# sourceMappingURL=auth.controller.d.ts.map