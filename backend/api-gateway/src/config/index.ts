import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load .env from the root of handy-go
dotenv.config({ path: resolve(__dirname, '../../../../.env') });

// Every microservice's routes are now mounted directly in this same
// process (see index.ts) instead of being proxied to separate servers.
// Some services still make internal HTTP calls to "other services" for
// notifications/matching/user lookups (e.g. booking-service calling
// notification-service) — those must now unconditionally resolve back to
// this same process's own port, overriding whatever the shared .env file
// says (it still hardcodes the old per-service ports for standalone
// local-dev use, which never loads this file at all). This runs before
// this module's `import`s further down the entry point pull in those
// services' route modules (which read these vars at import time), so
// the override is already in place by the time they do.
const selfServiceUrl = `http://localhost:${process.env.PORT || 3000}`;
process.env.MATCHING_SERVICE_URL = selfServiceUrl;
process.env.NOTIFICATION_SERVICE_URL = selfServiceUrl;
process.env.USER_SERVICE_URL = selfServiceUrl;

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'production',
  localDevMode: process.env.LOCAL_DEV_MODE === 'true',

  // MongoDB — the gateway now owns the single shared connection used by
  // every microservice's routes, which are mounted directly in-process
  // (see index.ts) instead of being proxied to separate servers.
  mongodbUri:
    process.env.MONGODB_URI ||
    'mongodb://handygo_app:handygo_app_password@localhost:27017/handygo?authSource=handygo',

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
