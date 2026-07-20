/**
 * Payments API — local synthetic payment views derived from bookings.
 */
import { getData } from './client';

const mapTransaction = (booking: any) => {
  const amount = booking.pricing?.finalPrice || booking.pricing?.estimatedPrice || 0;
  const statusMap: Record<string, string> = {
    COMPLETED: 'COMPLETED',
    CANCELLED: 'REVERSED',
    PENDING: 'PENDING',
    ACCEPTED: 'PENDING',
    IN_PROGRESS: 'PENDING',
  };

  return {
    _id: booking._id,
    userId: booking.customer?._id ?? '',
    type: booking.status === 'CANCELLED' ? 'REFUND' : 'BOOKING_DEBIT',
    amount,
    status: statusMap[booking.status] ?? 'PENDING',
    bookingId: booking._id,
    paymentMethod: 'LOCAL',
    description: `${booking.serviceCategory ?? 'Service'} booking`,
    gatewayReference: booking.bookingNumber ?? null,
    createdAt: booking.createdAt,
    updatedAt: booking.updatedAt ?? booking.createdAt,
  };
};

export const paymentsApi = {
  /**
   * Get aggregate transaction counts by type and a revenue summary.
   */
  getTransactionStats: async () => {
    const { data } = await getData<any>('/bookings/admin/stats', { period: 'month' });
    const summary = data?.summary ?? {};

    return {
      total: summary.totalBookings ?? 0,
      topUps: 0,
      bookingPayments: summary.completedBookings ?? 0,
      earnings: 0,
      withdrawals: 0,
      refunds: summary.cancelledBookings ?? 0,
      completed: summary.completedBookings ?? 0,
      totalRevenue: summary.totalPlatformFees ?? 0,
    };
  },

  /**
   * List transactions with optional filters + pagination.
   */
  getTransactions: async (params?: {
    page?: number;
    limit?: number;
    type?: string;
    status?: string;
    search?: string;
  }) => {
    const { data, meta } = await getData<any[]>('/bookings/admin', {
      page: params?.page ?? 1,
      limit: params?.limit ?? 10,
    });

    let transactions = (data ?? []).map(mapTransaction);

    if (params?.type) {
      transactions = transactions.filter((txn) => txn.type === params.type);
    }

    if (params?.status) {
      transactions = transactions.filter((txn) => txn.status === params.status);
    }

    if (params?.search) {
      const needle = params.search.toLowerCase();
      transactions = transactions.filter((txn) => txn.description.toLowerCase().includes(needle));
    }

    return {
      success: true,
      transactions,
      total: meta?.total ?? transactions.length,
    };
  },

  /**
   * List all wallets with optional pagination.
   */
  getWallets: async (params?: { page?: number; limit?: number; search?: string }) => {
    return {
      success: true,
      wallets: [],
      total: 0,
    };
  },
};
