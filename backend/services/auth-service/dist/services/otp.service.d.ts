import { OTPPurpose } from '@handy-go/shared';
/**
 * Generate 6-digit OTP using cryptographically secure random
 */
export declare const generateOTP: () => string;
/**
 * Send SMS via Twilio
 */
export declare const sendSMS: (phone: string, message: string) => Promise<boolean>;
/**
 * Create OTP record and send SMS
 */
export declare const createAndSendOTP: (phone: string, purpose: OTPPurpose) => Promise<{
    success: boolean;
    otpId?: string;
    error?: string;
}>;
/**
 * Verify OTP code
 */
export declare const verifyOTPCode: (phone: string, code: string, purpose: OTPPurpose) => Promise<{
    success: boolean;
    error?: string;
}>;
//# sourceMappingURL=otp.service.d.ts.map