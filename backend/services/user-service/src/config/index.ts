import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
dotenv.config({ path: resolve(__dirname, '../../../../../.env') });

export const config = {
  port: parseInt(process.env.USER_SERVICE_PORT || process.env.PORT || '3002', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  mongodbUri:
    process.env.MONGODB_URI ||
    'mongodb://handygo_app:handygo_app_password@localhost:27017/handygo?authSource=handygo',
  jwtSecret: process.env.JWT_SECRET || 'your-super-secret-jwt-key',
  corsOrigin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],

  // Cloudinary
  cloudinary: {
    cloudName: process.env.CLOUDINARY_CLOUD_NAME || '',
    apiKey: process.env.CLOUDINARY_API_KEY || '',
    apiSecret: process.env.CLOUDINARY_API_SECRET || '',
  },
};

export default config;
