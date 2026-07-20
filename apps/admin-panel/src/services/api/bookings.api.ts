/**
 * Bookings API — local backend booking management for admin panel.
 */
import { apiRequest, getData } from './client';

const formatDayName = (dateString: string) =>
  new Date(dateString).toLocaleDateString(undefined, { weekday: 'short' });

const mapBooking = (doc: any) => ({
  _id: doc._id,
  bookingNumber: doc.bookingNumber ?? doc._id,
  customer: {
    firstName: doc.customer?.firstName ?? 'Unknown',
    lastName: doc.customer?.lastName ?? '',
    phone: doc.customer?.phone ?? '',
  },
  worker: doc.worker
    ? {
        firstName: doc.worker.firstName ?? 'Unknown',
        lastName: doc.worker.lastName ?? '',
        phone: doc.worker.phone ?? '',
      }
    : undefined,
  serviceCategory: doc.serviceCategory ?? 'Unknown',
  problemDescription: doc.problemDescription ?? '',
  address: {
    full: doc.address?.full ?? doc.address?.address ?? '',
    city: doc.address?.city ?? '',
  },
  scheduledDateTime: doc.scheduledDateTime ?? doc.createdAt,
  status: doc.status ?? 'PENDING',
  pricing: doc.pricing ?? { estimatedPrice: 0 },
  timeline: Array.isArray(doc.timeline) ? doc.timeline : [],
  createdAt: doc.createdAt,
});

export const bookingsApi = {
  getBookingStatusCounts: async () => {
    const { data } = await getData<any>('/bookings/admin/stats', { period: 'month' });
    const summary = data?.summary ?? {};

    return {
      total: summary.totalBookings ?? 0,
      pending: summary.pendingBookings ?? 0,
      inProgress: summary.inProgressBookings ?? 0,
      completed: summary.completedBookings ?? 0,
      cancelled: summary.cancelledBookings ?? 0,
    };
  },

  getBookings: async (params?: {
    page?: number;
    limit?: number;
    status?: string;
    serviceCategory?: string;
    startDate?: string;
    endDate?: string;
  }) => {
    const { data, meta } = await getData<any[]>('/bookings/admin', {
      page: params?.page ?? 1,
      limit: params?.limit ?? 10,
      status: params?.status,
      serviceCategory: params?.serviceCategory,
      startDate: params?.startDate,
      endDate: params?.endDate,
    });

    return {
      success: true,
      bookings: (data ?? []).map(mapBooking),
      total: meta?.total ?? 0,
      page: meta?.page ?? params?.page ?? 1,
      limit: meta?.limit ?? params?.limit ?? 10,
    };
  },

  getBookingStats: async (period: 'day' | 'week' | 'month') => {
    const [statsResponse, workersResponse, customersResponse, recentResponse] = await Promise.all([
      getData<any>('/bookings/admin/stats', { period }),
      getData<any[]>('/users/admin/workers', { page: 1, limit: 1, verificationStatus: 'ACTIVE' }),
      getData<any[]>('/users/admin/customers', { page: 1, limit: 1 }),
      getData<any[]>('/bookings/admin', { page: 1, limit: 5 }),
    ]);

    const summary = statsResponse.data?.summary ?? {};
    const dailyBreakdown = statsResponse.data?.dailyBreakdown ?? [];
    const categoryBreakdown = statsResponse.data?.categoryBreakdown ?? [];
    const recentBookings = (recentResponse.data ?? []).map(mapBooking);

    return {
      success: true,
      stats: {
        totalBookings: summary.totalBookings ?? 0,
        completedBookings: summary.completedBookings ?? 0,
        cancelledBookings: summary.cancelledBookings ?? 0,
        pendingBookings: summary.pendingBookings ?? 0,
        inProgressBookings: summary.inProgressBookings ?? 0,
        averageRating: summary.averageRating ?? 0,
        totalRevenue: summary.totalRevenue ?? 0,
        totalCustomers: customersResponse.meta?.total ?? 0,
        activeWorkers: workersResponse.meta?.total ?? 0,
        dailyBookings: dailyBreakdown.map((item: any) => ({
          date: item._id,
          dayName: formatDayName(item._id),
          bookings: item.bookings ?? 0,
        })),
        monthlyRevenue: dailyBreakdown.map((item: any) => ({
          month: item._id,
          revenue: item.revenue ?? 0,
        })),
        categoryDistribution: categoryBreakdown.map((item: any, index: number) => ({
          name: item._id ?? 'Unknown',
          value: item.count ?? 0,
          color: ['#2196F3', '#4CAF50', '#FF9800', '#9C27B0', '#795548'][index % 5],
        })),
        recentBookings: recentBookings.map((booking) => ({
          id: booking.bookingNumber,
          customer: `${booking.customer.firstName} ${booking.customer.lastName}`.trim(),
          service: booking.serviceCategory,
          status: booking.status,
          amount: booking.pricing.finalPrice || booking.pricing.estimatedPrice || 0,
        })),
      },
    };
  },

  updateBooking: async (bookingId: string, data: { status?: string; notes?: string }) => {
    const response = await apiRequest<any>(`/bookings/admin/${bookingId}`, {
      method: 'PUT',
      body: data,
    });

    return { success: true, booking: response.data ? mapBooking(response.data) : null };
  },
};
