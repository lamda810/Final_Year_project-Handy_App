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
  '/',
  '/health',
  '/api/health',
  // Uploaded files are served statically and referenced by URL from
  // authenticated responses (e.g. booking images) — the URL itself is
  // the access control, same as any other static asset host.
  '/uploads',
  // Internal service-to-service endpoints, protected by their own
  // authenticateService (X-Service-Key) check at the router level rather
  // than a client JWT. Before all services were merged into this one
  // process, these calls (e.g. sos-service -> notification-service) went
  // directly between separate servers and never touched the gateway's
  // JWT check at all — now that they're routed through the same app,
  // they need this exemption to keep working the same way.
  '/api/notifications/send',
  '/api/notifications/send-templated',
  '/api/notifications/send-bulk',
  '/api/matching/calculate-trust-score',
  '/api/matching/update-trust-score',
  '/api/matching/auto-replace-worker',
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
