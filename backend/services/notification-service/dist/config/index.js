import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
dotenv.config({ path: resolve(__dirname, '../../../../../.env') });
export const config = {
    nodeEnv: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.NOTIFICATION_SERVICE_PORT || process.env.PORT || '3005', 10),
    mongoUri: process.env.MONGODB_URI ||
        'mongodb://handygo_app:handygo_app_password@localhost:27017/handygo?authSource=handygo',
    jwt: {
        secret: process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production',
    },
    corsOrigins: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000'],
    // Internal service communication
    serviceKey: process.env.SERVICE_KEY || 'internal-service-key',
    // Firebase Cloud Messaging
    firebase: {
        projectId: process.env.FIREBASE_PROJECT_ID || '',
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n') || '',
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL || '',
    },
    // Twilio SMS
    twilio: {
        accountSid: process.env.TWILIO_ACCOUNT_SID || '',
        authToken: process.env.TWILIO_AUTH_TOKEN || '',
        phoneNumber: process.env.TWILIO_PHONE_NUMBER || '',
    },
    // Email (Nodemailer)
    email: {
        host: process.env.EMAIL_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.EMAIL_PORT || '587', 10),
        secure: process.env.EMAIL_SECURE === 'true',
        user: process.env.EMAIL_USER || '',
        password: process.env.EMAIL_PASSWORD || '',
        fromName: process.env.EMAIL_FROM_NAME || 'Handy Go',
        fromEmail: process.env.EMAIL_FROM || 'noreply@handygo.pk',
    },
    // Notification settings
    notifications: {
        defaultChannels: ['push', 'inapp'],
        maxRetries: parseInt(process.env.NOTIFICATION_MAX_RETRIES || '3', 10),
        retryDelayMs: parseInt(process.env.NOTIFICATION_RETRY_DELAY || '1000', 10),
    },
};
//# sourceMappingURL=index.js.map