import { createProxyMiddleware } from 'http-proxy-middleware';
import { logger } from '@handy-go/shared';
import { serviceRoutes, getServiceForPath } from '../config/routes.js';
import { config } from '../config/index.js';
/**
 * Create proxy middleware for a service
 */
export const createServiceProxy = (target, path) => {
    return createProxyMiddleware({
        target,
        changeOrigin: true,
        ws: true, // Enable WebSocket proxying
        timeout: 30000,
        proxyTimeout: 30000,
        onProxyReq: (proxyReq, req, res) => {
            const extReq = req;
            // Guard: If response was already sent (e.g., by rate limiter), abort the proxy request
            if (res.headersSent) {
                proxyReq.destroy();
                return; // Must return to prevent further header/body writes on destroyed request
            }
            // Forward request ID first (before any body operations)
            if (extReq.requestId) {
                proxyReq.setHeader('X-Request-ID', extReq.requestId);
            }
            // Forward user info
            if (extReq.headers['x-user-id']) {
                proxyReq.setHeader('X-User-ID', extReq.headers['x-user-id']);
            }
            if (extReq.headers['x-user-role']) {
                proxyReq.setHeader('X-User-Role', extReq.headers['x-user-role']);
            }
            // Add service key for internal communication
            proxyReq.setHeader('X-Service-Key', config.serviceKey);
            // Restream body if it was parsed by express.json()
            // This must be done LAST after all headers are set
            if (extReq.body && Object.keys(extReq.body).length > 0) {
                const bodyData = JSON.stringify(extReq.body);
                proxyReq.setHeader('Content-Type', 'application/json');
                proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
                proxyReq.write(bodyData);
            }
            logger.debug('Proxying request', {
                path: req.path,
                target,
                method: req.method,
            });
        },
        onProxyRes: (proxyRes, req, res) => {
            // Log response from service
            logger.debug('Proxy response', {
                path: req.url,
                status: proxyRes.statusCode,
            });
        },
        onError: (err, req, res) => {
            logger.error('Proxy error', {
                error: err.message,
                path: req.url,
                target,
            });
            const response = res;
            if (!response.headersSent) {
                response.writeHead(503, { 'Content-Type': 'application/json' });
                response.end(JSON.stringify({
                    success: false,
                    message: 'Service temporarily unavailable',
                    error: config.nodeEnv === 'development' ? err.message : undefined,
                }));
            }
        },
    });
};
/**
 * Dynamic proxy router that selects the appropriate service
 */
export const proxyRouter = async (req, res, next) => {
    const serviceConfig = getServiceForPath(req.path);
    if (!serviceConfig) {
        return res.status(404).json({
            success: false,
            message: 'Route not found',
        });
    }
    const proxy = createServiceProxy(serviceConfig.target, serviceConfig.path);
    return proxy(req, res, next);
};
/**
 * Set up all service proxies
 */
export const setupProxies = (app) => {
    serviceRoutes.forEach(route => {
        const proxyMiddleware = createServiceProxy(route.target, route.path);
        app.use(route.path, proxyMiddleware);
        logger.info(`Proxy configured: ${route.path} -> ${route.target}`);
    });
};
//# sourceMappingURL=proxy.js.map