import { Router } from 'express';
import { authLimiter, otpLimiter } from '@handy-go/shared';
import { sendOTP, verifyOTP, registerCustomer, registerWorker, login, logout, refreshToken, forgotPassword, resetPassword, } from '../controllers/auth.controller.js';
const router = Router();
// OTP endpoints (with stricter rate limiting)
router.post('/send-otp', otpLimiter, sendOTP);
router.post('/verify-otp', authLimiter, verifyOTP);
// Registration endpoints
router.post('/register/customer', authLimiter, registerCustomer);
router.post('/register/worker', authLimiter, registerWorker);
// Login endpoint
router.post('/login', authLimiter, login);
// Logout endpoint
router.post('/logout', logout);
// Token refresh endpoint
router.post('/refresh-token', refreshToken);
// Password reset endpoints
router.post('/forgot-password', otpLimiter, forgotPassword);
router.post('/reset-password', authLimiter, resetPassword);
export default router;
//# sourceMappingURL=auth.routes.js.map