/**
 * Realtime subscriptions are disabled in local-only mode.
 */

export const realtimeApi = {
  subscribeToSOS: (_callback: (payload: Record<string, unknown>) => void) => () => {},

  subscribeToBookings: (_callback: (payload: Record<string, unknown>) => void) => () => {},
};
