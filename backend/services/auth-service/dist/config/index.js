import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
// ES module path resolution
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
// Load .env from project root (5 levels up from config folder: config -> src -> auth-service -> services -> backend -> handy-go)
dotenv.config({ path: resolve(__dirname, '../../../../../.env') });
export const config = {
    // Server
    port: parseInt(process.env.AUTH_SERVICE_PORT || process.env.PORT || '3001', 10),
    nodeEnv: process.env.NODE_ENV || 'development',
    // MongoDB
    mongodbUri: process.env.MONGODB_URI ||
        'mongodb://handygo_app:handygo_app_password@localhost:27017/handygo?authSource=handygo',
    // JWT
    jwtSecret: process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production',
    jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
    jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || 'your-refresh-token-secret-change-in-production',
    jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
    // Twilio
    twilioAccountSid: process.env.TWILIO_ACCOUNT_SID || '',
    twilioAuthToken: process.env.TWILIO_AUTH_TOKEN || '',
    twilioPhoneNumber: process.env.TWILIO_PHONE_NUMBER || '',
    // OTP
    otpExpiryMinutes: parseInt(process.env.OTP_EXPIRY_MINUTES || '5', 10),
    otpMaxAttempts: parseInt(process.env.OTP_MAX_ATTEMPTS || '3', 10),
    // CORS
    corsOrigin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
};
// Validate required environment variables in production
if (config.nodeEnv === 'production') {
    const requiredEnvVars = [
        'JWT_SECRET',
        'JWT_REFRESH_SECRET',
        'MONGODB_URI',
        'TWILIO_ACCOUNT_SID',
        'TWILIO_AUTH_TOKEN',
        'TWILIO_PHONE_NUMBER',
    ];
    for (const envVar of requiredEnvVars) {
        if (!process.env[envVar]) {
            throw new Error(`Missing required environment variable: ${envVar}`);
        }
    }
}
export default config;
//# sourceMappingURL=index.js.map