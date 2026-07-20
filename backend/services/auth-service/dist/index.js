import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import mongoose from 'mongoose';
import { config } from './config/index.js';
import { errorHandler, notFoundHandler, morganStream, logger } from '@handy-go/shared';
import authRoutes from './routes/auth.routes.js';
// Create Express app
const app = express();
// Security middleware
app.use(helmet());
// CORS configuration
app.use(cors({
    origin: config.corsOrigin,
    credentials: true,
}));
// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
// Request logging
if (config.nodeEnv === 'development') {
    app.use(morgan('dev'));
}
else {
    app.use(morgan('combined', { stream: morganStream }));
}
// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        service: 'auth-service',
        timestamp: new Date().toISOString(),
        mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    });
});
// API routes
app.use('/api/auth', authRoutes);
// 404 handler
app.use(notFoundHandler);
// Global error handler
app.use(errorHandler);
// Database connection and server start
const startServer = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect(config.mongodbUri);
        logger.info('Connected to MongoDB');
        // Start server
        app.listen(config.port, () => {
            logger.info(`Auth service running on port ${config.port}`);
            logger.info(`Environment: ${config.nodeEnv}`);
        });
    }
    catch (error) {
        logger.error('Failed to start server', error);
        process.exit(1);
    }
};
// Handle graceful shutdown
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
// Start the server
startServer();
export default app;
//# sourceMappingURL=index.js.map