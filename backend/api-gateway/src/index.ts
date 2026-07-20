import express, { Request, Response, NextFunction, Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import path from 'path';
import { fileURLToPath } from 'url';
import mongoose from 'mongoose';
import { logger } from '@handy-go/shared';
import { config } from './config/index.js';
import { authenticate } from './middleware/auth.js';
import uploadRoutes from './routes/upload.routes.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
import {
  generalRateLimiter,
  authRateLimiter,
  authenticatedRateLimiter,
  sosRateLimiter
} from './middleware/rateLimiter.js';
import {
  requestId,
  requestLogger,
  securityHeaders,
  handlePreflight,
} from './middleware/common.js';
import { createLocalDevProtectedRouter, createLocalDevPublicRouter } from './local-dev/router.js';

// Every microservice's routes, mounted directly in-process instead of
// proxied over HTTP to separate servers. This exists because running 7
// separate Node processes (gateway + 6 services) exceeded Render's
// free-tier 512MB memory limit — one process with one shared MongoDB
// connection fits comfortably and removes an entire class of proxy bugs
// (body/Content-Length forwarding) this project had already hit once.
import authRoutes from '@handy-go/auth-service/dist/routes/auth.routes.js';
import userCustomerRoutes from '@handy-go/user-service/dist/routes/customer.routes.js';
import userWorkerRoutes from '@handy-go/user-service/dist/routes/worker.routes.js';
import userAdminRoutes from '@handy-go/user-service/dist/routes/admin.routes.js';
import bookingWorkerRoutes from '@handy-go/booking-service/dist/routes/worker.routes.js';
import bookingAdminRoutes from '@handy-go/booking-service/dist/routes/admin.routes.js';
import bookingChatRoutes from '@handy-go/booking-service/dist/routes/chat.routes.js';
import bookingCustomerRoutes from '@handy-go/booking-service/dist/routes/customer.routes.js';
import matchingRoutes from '@handy-go/matching-service/dist/routes/matching.routes.js';
import notificationRoutes from '@handy-go/notification-service/dist/routes/notification.routes.js';
import sosRoutes from '@handy-go/sos-service/dist/routes/sos.routes.js';
import { initializeBackgroundJobs as initBookingJobs } from '@handy-go/booking-service/dist/jobs/booking.jobs.js';
import { startAllJobs as startSosJobs } from '@handy-go/sos-service/dist/jobs/sos.jobs.js';

const app: Application = express();

// ==================== Global Middleware ====================

// Trust proxy (for rate limiting and IP detection behind reverse proxy)
app.set('trust proxy', 1);

// Security headers
app.use(helmet({
  contentSecurityPolicy: false, // Disable for API
  crossOriginEmbedderPolicy: false,
}));
app.use(securityHeaders);

// CORS
app.use(cors({
  origin: config.corsOrigins,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID', 'ngrok-skip-browser-warning'],
}));
app.use(handlePreflight);

// Compression
app.use(compression());

// Request ID and logging
app.use(requestId);
app.use(requestLogger);

// HTTP request logging
if (config.nodeEnv !== 'test') {
  app.use(morgan('combined', {
    stream: {
      write: (message: string) => logger.info(message.trim()),
    },
  }));
}

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ==================== Root ====================

app.get('/', (req, res) => {
  res.json({
    message: 'Hello World from Handy Go API Gateway',
  });
});

// ==================== Health Check ====================

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'api-gateway',
    timestamp: new Date().toISOString(),
    environment: config.nodeEnv,
    node_env: process.env.NODE_ENV,
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
  });
});

// Uploaded images (booking photos, profile photos, etc.) — local-disk
// storage served statically. Public per config/routes.ts's publicRoutes.
app.use('/uploads', express.static(path.resolve(__dirname, '../uploads')));

app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'api-gateway',
    timestamp: new Date().toISOString(),
    localDevMode: config.localDevMode,
  });
});

// ==================== Rate Limiting ====================

// Apply rate limiting based on route
app.use('/api/auth', authRateLimiter);
app.use('/api/sos', sosRateLimiter);

if (config.localDevMode) {
  logger.info('Running API Gateway in local dev mode without Docker or microservices');
  app.use(createLocalDevPublicRouter());
}

// ==================== Authentication ====================

// Authenticate requests (skips public routes)
app.use(authenticate);

// Apply authenticated rate limiter after auth
app.use(authenticatedRateLimiter);

if (config.localDevMode) {
  app.use(createLocalDevProtectedRouter());
}

// ==================== File Uploads ====================

// Handled directly in the gateway — multipart/form-data bodies through
// http-proxy-middleware have already been a source of bugs here.
app.use('/api/uploads', uploadRoutes);

// ==================== Service Routes ====================

if (!config.localDevMode) {
  app.use('/api/auth', authRoutes);

  app.use('/api/users/customer', userCustomerRoutes);
  app.use('/api/users/worker', userWorkerRoutes);
  app.use('/api/users/admin', userAdminRoutes);

  // Specific prefixes must be mounted before the customer router: it is
  // mounted at /api/bookings with router-level authorize('CUSTOMER'),
  // which would 403 worker/admin requests before their routers are reached.
  app.use('/api/bookings/worker', bookingWorkerRoutes);
  app.use('/api/bookings/admin', bookingAdminRoutes);
  app.use('/api/bookings', bookingChatRoutes);
  app.use('/api/bookings', bookingCustomerRoutes);

  app.use('/api/matching', matchingRoutes);
  app.use('/api/notifications', notificationRoutes);
  app.use('/api/sos', sosRoutes);
}

// ==================== 404 Handler ====================

app.use((req, res) => {
  if (res.headersSent) return;
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.path,
  });
});

// ==================== Error Handler ====================

app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  logger.error('Unhandled error:', {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  if (res.headersSent) {
    return next(err);
  }

  res.status(err.status || 500).json({
    success: false,
    message: config.nodeEnv === 'production'
      ? 'Internal server error'
      : err.message,
    ...(config.nodeEnv === 'development' && { stack: err.stack }),
  });
});

// ==================== Server Start ====================

const startServer = async () => {
  if (!config.localDevMode) {
    await mongoose.connect(config.mongodbUri);
    logger.info('Connected to MongoDB');

    initBookingJobs();
    startSosJobs();
    logger.info('Background jobs initialized');
  }

  const server = app.listen(config.port, () => {
    logger.info(`🚀 API Gateway running on port ${config.port}`);
    logger.info(`Environment: ${config.nodeEnv}`);
    logger.info(`Local dev mode: ${config.localDevMode ? 'enabled' : 'disabled'}`);
    logger.info('Server is now listening for connections...');
  });

  server.on('error', (error: Error) => {
    logger.error('Server error:', error);
    process.exit(1);
  });

  server.on('close', () => {
    logger.info('Server closed');
  });

  server.on('listening', () => {
    logger.info('Server is listening!');
  });

  // Keep the process alive
  server.keepAliveTimeout = 65000;
  server.headersTimeout = 66000;

  return server;
};

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  logger.error('Uncaught Exception:', error);
  // Node.js docs: state is undefined after uncaughtException — always exit.
  // In production, a process manager (PM2/k8s) will restart the process.
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received. Shutting down gracefully...');
  await mongoose.connection.close();
  process.exit(0);
});

startServer();

export default app;
