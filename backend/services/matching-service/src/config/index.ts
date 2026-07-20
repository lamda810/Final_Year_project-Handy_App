import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
dotenv.config({ path: resolve(__dirname, '../../../../../.env') });

export const config = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.MATCHING_SERVICE_PORT || process.env.PORT || '3004', 10),
  mongodbUri:
    process.env.MONGODB_URI ||
    'mongodb://handygo_app:handygo_app_password@localhost:27017/handygo?authSource=handygo',
  corsOrigin: process.env.CORS_ORIGIN || '*',

  // JWT configuration
  jwt: {
    secret: process.env.JWT_SECRET || 'your-super-secret-jwt-key',
  },

  // Service-to-service authentication key
  serviceKey: process.env.INTERNAL_SERVICE_KEY || 'internal-service-key',

  // Matching algorithm weights
  matching: {
    weights: {
      distance: parseFloat(process.env.WEIGHT_DISTANCE || '0.25'),
      rating: parseFloat(process.env.WEIGHT_RATING || '0.25'),
      trustScore: parseFloat(process.env.WEIGHT_TRUST_SCORE || '0.20'),
      experience: parseFloat(process.env.WEIGHT_EXPERIENCE || '0.15'),
      workload: parseFloat(process.env.WEIGHT_WORKLOAD || '0.15'),
    },
    maxDistance: parseInt(process.env.MAX_MATCHING_DISTANCE || '25', 10), // km
    minTrustScore: parseInt(process.env.MIN_TRUST_SCORE || '30', 10),
    resultsLimit: parseInt(process.env.MATCHING_RESULTS_LIMIT || '10', 10),
  },

  // Price estimation settings
  pricing: {
    bufferPercent: parseInt(process.env.PRICE_BUFFER_PERCENT || '20', 10),
    locationMultipliers: {
      karachi: 1.0,
      lahore: 0.95,
      islamabad: 1.1,
      rawalpindi: 0.9,
      faisalabad: 0.85,
      multan: 0.8,
      peshawar: 0.85,
      quetta: 0.9,
      default: 0.9,
    },
  },

  // Trust score calculation
  trustScore: {
    weights: {
      rating: 0.30,
      completionRate: 0.25,
      onTimeRate: 0.20,
      complaints: 0.15,
      accountAge: 0.10,
    },
  },
};
