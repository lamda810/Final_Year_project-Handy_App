/**
 * Users API — local backend customer & worker management.
 */
import { getData, apiRequest } from './client';

const monthStart = new Date(new Date().getFullYear(), new Date().getMonth(), 1);

const mapCustomer = (doc: any) => {
  const user = doc.user ?? {};

  return {
    _id: user._id ?? doc.user ?? doc._id,
    firstName: doc.firstName ?? '',
    lastName: doc.lastName ?? '',
    profileImage: doc.profileImage,
    phone: user.phone ?? '',
    email: user.email ?? '',
    addresses: Array.isArray(doc.addresses) ? doc.addresses : [],
    totalBookings: doc.totalBookings ?? 0,
    isActive: user.isActive ?? true,
    createdAt: user.createdAt ?? doc.createdAt,
  };
};

const mapWorker = (doc: any) => {
  const user = doc.user ?? {};

  return {
    _id: doc._id,
    userId: user._id ?? doc.user,
    firstName: doc.firstName ?? '',
    lastName: doc.lastName ?? '',
    profileImage: doc.profileImage,
    phone: user.phone ?? '',
    cnic: doc.cnic ?? '',
    cnicVerified: doc.cnicVerified ?? false,
    skills: Array.isArray(doc.skills) ? doc.skills : [],
    rating: doc.rating ?? { average: 0, count: 0 },
    trustScore: doc.trustScore ?? 0,
    totalJobsCompleted: doc.totalJobsCompleted ?? 0,
    status: doc.status ?? 'PENDING_VERIFICATION',
    createdAt: user.createdAt ?? doc.createdAt,
  };
};

export const usersApi = {
  getCustomers: async (params?: { page?: number; limit?: number; search?: string }) => {
    const { data, meta } = await getData<any[]>('/users/admin/customers', {
      page: params?.page ?? 1,
      limit: params?.limit ?? 10,
      search: params?.search,
    });
    return {
      success: true,
      customers: (data ?? []).map(mapCustomer),
      total: meta?.total ?? 0,
      page: meta?.page ?? params?.page ?? 1,
      limit: meta?.limit ?? params?.limit ?? 10,
    };
  },

  getWorkers: async (params?: {
    page?: number;
    limit?: number;
    search?: string;
    status?: string;
  }) => {
    const { data, meta } = await getData<any[]>('/users/admin/workers', {
      page: params?.page ?? 1,
      limit: params?.limit ?? 10,
      search: params?.search,
      verificationStatus: params?.status,
    });
    return {
      success: true,
      workers: (data ?? []).map(mapWorker),
      total: meta?.total ?? 0,
      page: meta?.page ?? params?.page ?? 1,
      limit: meta?.limit ?? params?.limit ?? 10,
    };
  },

  getPendingWorkers: async () => {
    const { data } = await getData<any[]>('/users/admin/workers/pending');
    return {
      success: true,
      workers: (data ?? []).map(mapWorker),
    };
  },

  verifyWorker: async (
    workerId: string,
    data: { status: string; notes?: string },
  ) => {
    const response = await apiRequest<any>(`/users/admin/workers/${workerId}/verify`, {
      method: 'PUT',
      body: data,
    });

    return {
      success: true,
      worker: response.data ? mapWorker(response.data) : null,
    };
  },

  updateUserStatus: async (
    userId: string,
    data: { isActive: boolean; reason?: string },
  ) => {
    await apiRequest(`/users/admin/users/${userId}/status`, {
      method: 'PUT',
      body: data,
    });
    return { success: true };
  },

  getWorkerStats: async () => {
    const [total, active, pending, suspended] = await Promise.all([
      getData<any[]>('/users/admin/workers', { page: 1, limit: 1 }),
      getData<any[]>('/users/admin/workers', { page: 1, limit: 1, verificationStatus: 'ACTIVE' }),
      getData<any[]>('/users/admin/workers', { page: 1, limit: 1, verificationStatus: 'PENDING_VERIFICATION' }),
      getData<any[]>('/users/admin/workers', { page: 1, limit: 1, verificationStatus: 'SUSPENDED' }),
    ]);

    return {
      total: total.meta?.total ?? 0,
      active: active.meta?.total ?? 0,
      pending: pending.meta?.total ?? 0,
      suspended: suspended.meta?.total ?? 0,
    };
  },

  getCustomerStats: async () => {
    const [total, active, recentCustomers, bookingStats] = await Promise.all([
      getData<any[]>('/users/admin/customers', { page: 1, limit: 1 }),
      getData<any[]>('/users/admin/customers', { page: 1, limit: 1, status: 'active' }),
      getData<any[]>('/users/admin/customers', { page: 1, limit: 200 }),
      getData<any>('/bookings/admin/stats', { period: 'month' }),
    ]);

    const newThisMonth = (recentCustomers.data ?? [])
      .map(mapCustomer)
      .filter((customer) => new Date(customer.createdAt) >= monthStart).length;

    return {
      total: total.meta?.total ?? 0,
      active: active.meta?.total ?? 0,
      totalBookings: bookingStats.data?.summary?.totalBookings ?? 0,
      newThisMonth,
    };
  },
};
