import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
// Load .env from the root of handy-go
dotenv.config({ path: resolve(__dirname, '../../../../.env') });
export const config = {
    port: parseInt(process.env.PORT || '3000', 10),
    nodeEnv: process.env.NODE_ENV || 'production',
    localDevMode: process.env.LOCAL_DEV_MODE === 'true',
    jwt: {
        secret: process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production',
    },
    corsOrigins: process.env.CORS_ORIGINS?.split(',') || [
        'http://localhost:3000',
        'http://localhost:5173',
        'http://localhost:8080',
        'https://handy-go-1y91.onrender.com',
    ],
    // Redis configuration for rate limiting and caching
    redis: {
        url: process.env.REDIS_URL || 'redis://localhost:6379',
    },
    // Microservice URLs
    services: {
        auth: process.env.AUTH_SERVICE_URL || 'http://localhost:3001',
        user: process.env.USER_SERVICE_URL || 'http://localhost:3002',
        booking: process.env.BOOKING_SERVICE_URL || 'http://localhost:3003',
        matching: process.env.MATCHING_SERVICE_URL || 'http://localhost:3004',
        notification: process.env.NOTIFICATION_SERVICE_URL || 'http://localhost:3005',
        sos: process.env.SOS_SERVICE_URL || 'http://localhost:3006',
    },
    // Rate limiting configuration
    rateLimiting: {
        // General API rate limit
        general: {
            windowMs: 15 * 60 * 1000, // 15 minutes
            max: 100, // 100 requests per window
        },
        // Authentication endpoints (stricter)
        auth: {
            windowMs: 15 * 60 * 1000, // 15 minutes
            max: 20, // 20 requests per window
        },
        // Authenticated users (more generous)
        authenticated: {
            windowMs: 15 * 60 * 1000, // 15 minutes
            max: 500, // 500 requests per window
        },
        // SOS endpoints (very generous for emergencies)
        sos: {
            windowMs: 60 * 1000, // 1 minute
            max: 10, // 10 requests per minute
        },
    },
    // Request logging
    logging: {
        format: process.env.LOG_FORMAT || 'combined',
    },
    // Internal service key for service-to-service communication
    serviceKey: process.env.SERVICE_KEY || 'internal-service-key',
};
//# sourceMappingURL=index.js.map