import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import helmet from 'helmet';
import { logger, errorHandler, notFoundHandler } from '@handy-go/shared';
import { config } from './config/index.js';
// Import routes
import customerRoutes from './routes/customer.routes.js';
import workerRoutes from './routes/worker.routes.js';
import adminRoutes from './routes/admin.routes.js';
// Create Express app
const app = express();
// Security middleware
app.use(helmet());
app.use(cors({
    origin: config.corsOrigin,
    credentials: true,
}));
// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
// Request logging
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path}`, {
        ip: req.ip,
        userAgent: req.get('user-agent'),
    });
    next();
});
// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        service: 'user-service',
        timestamp: new Date().toISOString(),
        mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    });
});
// API routes
app.use('/api/users/customer', customerRoutes);
app.use('/api/users/worker', workerRoutes);
app.use('/api/users/admin', adminRoutes);
// 404 handler
app.use(notFoundHandler);
// Global error handler
app.use(errorHandler);
// Database connection and server startup
const startServer = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect(config.mongodbUri);
        logger.info('Connected to MongoDB');
        // Start server
        app.listen(config.port, () => {
            logger.info(`User Service running on port ${config.port}`);
            logger.info(`Environment: ${config.nodeEnv}`);
        });
    }
    catch (error) {
        logger.error('Failed to start server:', error);
        process.exit(1);
    }
};
// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('SIGTERM received. Shutting down gracefully...');
    await mongoose.connection.close();
    process.exit(0);
});
process.on('SIGINT', async () => {
    logger.info('SIGINT received. Shutting down gracefully...');
    await mongoose.connection.close();
    process.exit(0);
});
// Handle unhandled rejections
process.on('unhandledRejection', (reason) => {
    logger.error('Unhandled Rejection:', reason);
});
// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception:', error);
    process.exit(1);
});
startServer();
export default app;
//# sourceMappingURL=index.js.map