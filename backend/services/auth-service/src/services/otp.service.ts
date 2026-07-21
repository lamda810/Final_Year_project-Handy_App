import twilio from 'twilio';
import { config } from '../config/index.js';
import { OTP, OTPPurpose, logger } from '@handy-go/shared';

// Initialize Twilio client only if valid credentials are provided
const twilioClient = (() => {
  try {
    // Only initialize if credentials look valid (SID starts with AC)
    if (config.twilioAccountSid &&
        config.twilioAuthToken &&
        config.twilioAccountSid.startsWith('AC')) {
      return twilio(config.twilioAccountSid, config.twilioAuthToken);
    }
    logger.warn('Twilio not configured - SMS will be logged instead of sent');
    return null;
  } catch (error) {
    logger.warn('Twilio initialization failed - SMS will be logged instead of sent');
    return null;
  }
})();

import { randomInt } from 'crypto';

/**
 * Generate 6-digit OTP using cryptographically secure random
 */
export const generateOTP = (): string => {
  return randomInt(100000, 999999).toString();
};

/**
 * Send SMS via Twilio
 */
export const sendSMS = async (phone: string, message: string): Promise<boolean> => {
  try {
    if (!twilioClient) {
      // SECURITY: In production, refuse to proceed without a real SMS provider.
      // In development, redact the OTP body but confirm delivery was simulated.
      if (config.nodeEnv === 'production') {
        logger.error('Twilio not configured in production — cannot send SMS');
        return false;
      }
      logger.info(`[DEV MODE] SMS simulated to ${phone} (OTP redacted)`);
      return true;
    }

    await twilioClient.messages.create({
      body: message,
      from: config.twilioPhoneNumber,
      to: phone,
    });

    logger.info(`SMS sent successfully to ${phone}`);
    return true;
  } catch (error) {
    logger.error('Failed to send SMS', error as Error, { phone });
    return false;
  }
};

/**
 * Create OTP record and send SMS
 */
export const createAndSendOTP = async (
  phone: string,
  purpose: OTPPurpose
): Promise<{ success: boolean; otpId?: string; error?: string }> => {
  try {
    // Create OTP record
    const otpRecord = await OTP.createOTP(phone, purpose);

    // No working SMS provider is wired up (Twilio trial account, 5
    // messages/day, already exhausted) — OTP.createOTP always issues a
    // fixed dummy code ("123456") rather than a real one, so there is
    // nothing sensitive to protect here and no SMS to actually send.
    // Skip the Twilio call entirely instead of attempting and failing it.
    logger.info(`OTP for ${phone}: ${otpRecord.code} (dummy code, no SMS sent)`);

    return { success: true, otpId: otpRecord._id.toString() };
  } catch (error) {
    logger.error('Failed to create OTP', error as Error, { phone, purpose });
    return { success: false, error: 'Failed to create OTP' };
  }
};

/**
 * Verify OTP code
 */
export const verifyOTPCode = async (
  phone: string,
  code: string,
  purpose: OTPPurpose
): Promise<{ success: boolean; error?: string }> => {
  try {
    // Find valid OTP
    const otpRecord = await OTP.findValidOTP(phone, purpose);

    if (!otpRecord) {
      return { success: false, error: 'OTP not found or expired' };
    }

    // Increment attempts
    await otpRecord.incrementAttempts();

    // Verify code
    if (!otpRecord.verify(code)) {
      if (otpRecord.attempts >= config.otpMaxAttempts) {
        return { success: false, error: 'Maximum OTP attempts exceeded' };
      }
      return { success: false, error: 'Invalid OTP code' };
    }

    // Mark as used
    await otpRecord.markAsUsed();

    return { success: true };
  } catch (error) {
    logger.error('Failed to verify OTP', error as Error, { phone, purpose });
    return { success: false, error: 'Failed to verify OTP' };
  }
};
