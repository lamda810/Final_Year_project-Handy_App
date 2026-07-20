import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import path from 'path';
import { fileURLToPath } from 'url';
import { logger } from '@handy-go/shared';
import { config } from './config/index.js';
import { authenticate } from './middleware/auth.js';
import uploadRoutes from './routes/upload.routes.js';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
import { authRateLimiter, authenticatedRateLimiter, sosRateLimiter } from './middleware/rateLimiter.js';
import { requestId, requestLogger, securityHeaders, handlePreflight, } from './middleware/common.js';
import { setupProxies } from './middleware/proxy.js';
import { createLocalDevProtectedRouter, createLocalDevPublicRouter } from './local-dev/router.js';
const app = express();
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
            write: (message) => logger.info(message.trim()),
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
        services: Object.entries(config.services).map(([name, url]) => ({
            name,
            url,
        })),
        debug: {
            has_auth_url: !!process.env.AUTH_SERVICE_URL,
            auth_url_value: process.env.AUTH_SERVICE_URL || 'MISSING',
        }
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
// Handled directly in the gateway (not proxied) — multipart/form-data
// bodies through http-proxy-middleware have already been a source of
// bugs here (see the Content-Length fix in proxy.ts), so avoid that
// path entirely for file uploads.
app.use('/api/uploads', uploadRoutes);
// ==================== Service Proxies ====================
// Set up proxies to microservices
if (!config.localDevMode) {
    setupProxies(app);
}
// ==================== 404 Handler ====================
app.use((req, res) => {
    if (res.headersSent)
        return;
    res.status(404).json({
        success: false,
        message: 'Route not found',
        path: req.path,
    });
});
// ==================== Error Handler ====================
app.use((err, req, res, next) => {
    logger.error('Unhandled error:', {
        error: err.message,
        stack: err.stack,
        path: req.path,
        method: req.method,
    });
    // Guard: proxy onError may have already sent a response
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
const startServer = () => {
    const server = app.listen(config.port, () => {
        logger.info(`🚀 API Gateway running on port ${config.port}`);
        logger.info(`Environment: ${config.nodeEnv}`);
        logger.info(`Local dev mode: ${config.localDevMode ? 'enabled' : 'disabled'}`);
        logger.info('Configured services:');
        Object.entries(config.services).forEach(([name, url]) => {
            logger.info(`  - ${name}: ${url}`);
        });
        logger.info('Server is now listening for connections...');
    });
    server.on('error', (error) => {
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
process.on('SIGTERM', () => {
    logger.info('SIGTERM received. Shutting down gracefully...');
    process.exit(0);
});
startServer();
export default app;
//# sourceMappingURL=index.js.map