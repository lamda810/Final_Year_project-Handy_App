import { config } from '../config/index.js';

/**
 * Service route configuration
 * Maps API paths to their respective microservices
 */
export interface ServiceRoute {
  path: string;
  target: string;
  pathRewrite?: Record<string, string>;
  requiresAuth?: boolean;
  rateLimit?: 'general' | 'auth' | 'authenticated' | 'sos';
}

export const serviceRoutes: ServiceRoute[] = [
  // Authentication Service Routes
  {
    path: '/api/auth',
    target: config.services.auth,
    requiresAuth: false,
    rateLimit: 'auth',
  },

  // User Service Routes
  {
    path: '/api/users',
    target: config.services.user,
    requiresAuth: true,
    rateLimit: 'authenticated',
  },

  // Booking Service Routes
  {
    path: '/api/bookings',
    target: config.services.booking,
    requiresAuth: true,
    rateLimit: 'authenticated',
  },

  // Matching Service Routes
  {
    path: '/api/matching',
    target: config.services.matching,
    requiresAuth: true,
    rateLimit: 'authenticated',
  },

  // Notification Service Routes
  {
    path: '/api/notifications',
    target: config.services.notification,
    requiresAuth: true,
    rateLimit: 'authenticated',
  },

  // SOS Service Routes
  {
    path: '/api/sos',
    target: config.services.sos,
    requiresAuth: true,
    rateLimit: 'sos',
  },
];

/**
 * Public routes that don't require authentication
 */
export const publicRoutes = [
  '/api/auth/send-otp',
  '/api/auth/verify-otp',
  '/api/auth/register/customer',
  '/api/auth/register/worker',
  '/api/auth/login',
  '/api/auth/refresh-token',
  '/api/auth/forgot-password',
  '/api/auth/reset-password',
  '/health',
  '/api/health',
  // Uploaded files are served statically and referenced by URL from
  // authenticated responses (e.g. booking images) — the URL itself is
  // the access control, same as any other static asset host.
  '/uploads',
];

/**
 * Check if a route is public (doesn't require authentication)
 */
export const isPublicRoute = (path: string): boolean => {
  return publicRoutes.some(route => {
    // Exact match or starts with (for patterns like /api/auth/*)
    return path === route || path.startsWith(route + '/');
  });
};

/**
 * Get the service configuration for a given path
 */
export const getServiceForPath = (path: string): ServiceRoute | undefined => {
  return serviceRoutes.find(route => path.startsWith(route.path));
};
