import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
dotenv.config({ path: resolve(__dirname, '../../../../../.env') });

export const config = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.BOOKING_SERVICE_PORT || process.env.PORT || '3003', 10),
  mongodbUri:
    process.env.MONGODB_URI ||
    'mongodb://handygo_app:handygo_app_password@localhost:27017/handygo?authSource=handygo',
  jwtSecret: process.env.JWT_SECRET || 'your-super-secret-jwt-key',
  corsOrigin: process.env.CORS_ORIGIN || '*',

  // Service URLs for inter-service communication
  services: {
    matching: process.env.MATCHING_SERVICE_URL || 'http://localhost:3004',
    notification: process.env.NOTIFICATION_SERVICE_URL || 'http://localhost:3005',
    user: process.env.USER_SERVICE_URL || 'http://localhost:3002',
  },

  // Booking settings
  booking: {
    workerAcceptanceTimeout: parseInt(process.env.WORKER_ACCEPTANCE_TIMEOUT || '300', 10), // 5 minutes in seconds
    cancellationWindowHours: parseInt(process.env.CANCELLATION_WINDOW_HOURS || '2', 10),
    cancellationPenaltyPercent: parseInt(process.env.CANCELLATION_PENALTY_PERCENT || '10', 10),
    maxActiveBookingsPerCustomer: parseInt(process.env.MAX_ACTIVE_BOOKINGS || '3', 10),
    reminderBeforeMinutes: parseInt(process.env.REMINDER_BEFORE_MINUTES || '30', 10),
  },

  // Platform fee settings
  platformFee: {
    percentage: parseFloat(process.env.PLATFORM_FEE_PERCENT || '15'), // 15%
    minFee: parseInt(process.env.PLATFORM_MIN_FEE || '50', 10), // Rs. 50 minimum
    maxFee: parseInt(process.env.PLATFORM_MAX_FEE || '500', 10), // Rs. 500 maximum
  },

  // Redis for real-time features (optional)
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD || '',
  },
};
