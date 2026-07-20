/**
 * SOS API — local backend emergency alert management for admin panel.
 */
import { apiRequest, getData } from './client';

const mapSOS = (doc: any) => ({
  _id: doc._id,
  booking: doc.booking
    ? {
        bookingNumber: doc.booking.bookingNumber ?? doc.booking._id,
        serviceCategory: doc.booking.serviceCategory ?? 'Unknown',
      }
    : undefined,
  initiatedBy: {
    userType: doc.initiatedBy?.userType ?? 'CUSTOMER',
    userId: doc.initiatedBy?.userId?._id ?? doc.initiatedBy?.userId ?? '',
    name: doc.initiatedBy?.userId?.phone ?? 'Unknown',
    phone: doc.initiatedBy?.userId?.phone ?? '',
  },
  priority: doc.priority ?? 'LOW',
  reason: doc.reason ?? '',
  description: doc.description ?? '',
  location: doc.location ?? { coordinates: [0, 0] },
  status: doc.status ?? 'ACTIVE',
  createdAt: doc.createdAt,
});

export const sosApi = {
  getActiveSOS: async () => {
    const { data } = await getData<any[]>('/sos/admin/active', { page: 1, limit: 100 });

    return {
      success: true,
      alerts: (data ?? []).map(mapSOS),
    };
  },

  assignSOS: async (sosId: string) => {
    await apiRequest(`/sos/admin/${sosId}/assign`, {
      method: 'POST',
    });
    return { success: true };
  },

  resolveSOS: async (sosId: string, data: { action: string; notes: string }) => {
    const response = await apiRequest<any>(`/sos/admin/${sosId}/resolve`, {
      method: 'POST',
      body: data,
    });
    return { success: true, sos: response.data ? mapSOS(response.data) : null };
  },

  escalateSOS: async (sosId: string, data: { reason: string }) => {
    await apiRequest(`/sos/admin/${sosId}/escalate`, {
      method: 'POST',
      body: data,
    });
    return { success: true };
  },
};
