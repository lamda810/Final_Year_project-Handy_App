import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
dotenv.config({ path: resolve(__dirname, '../../../../../.env') });
export const config = {
    port: parseInt(process.env.SOS_SERVICE_PORT || process.env.PORT || '3006', 10),
    nodeEnv: process.env.NODE_ENV || 'development',
    mongoUri: process.env.MONGODB_URI ||
        'mongodb://handygo_app:handygo_app_password@localhost:27017/handygo?authSource=handygo',
    jwt: {
        secret: process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production',
    },
    corsOrigins: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000'],
    // Service communication
    serviceKey: process.env.SERVICE_KEY || 'internal-service-key',
    notificationServiceUrl: process.env.NOTIFICATION_SERVICE_URL || 'http://localhost:3005',
    // SOS Configuration
    sos: {
        // Time before auto-escalation (in minutes)
        autoEscalateMinutes: parseInt(process.env.SOS_AUTO_ESCALATE_MINUTES || '10', 10),
        // Maximum response time for admin (in minutes)
        maxResponseTimeMinutes: parseInt(process.env.SOS_MAX_RESPONSE_MINUTES || '5', 10),
        // Radius to search for nearby admins/support (in km)
        supportRadius: parseInt(process.env.SOS_SUPPORT_RADIUS || '50', 10),
    },
    // Emergency contacts
    emergencyContacts: {
        police: process.env.EMERGENCY_POLICE || '15',
        ambulance: process.env.EMERGENCY_AMBULANCE || '115',
        helpline: process.env.EMERGENCY_HELPLINE || '1166',
    },
};
//# sourceMappingURL=index.js.map