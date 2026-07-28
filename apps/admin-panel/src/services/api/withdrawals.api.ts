/**
 * Withdrawals API — worker payout request review for admin panel.
 */
import { apiRequest, getData } from './client';

const mapWithdrawal = (doc: any) => {
  const worker = doc.worker ?? {};
  const user = worker.user ?? {};

  return {
    _id: doc._id,
    worker: {
      _id: worker._id ?? doc.worker,
      firstName: worker.firstName ?? '',
      lastName: worker.lastName ?? '',
      phone: user.phone ?? worker.contactPhone ?? '',
    },
    amount: doc.amount ?? 0,
    bankDetails: doc.bankDetails ?? { accountTitle: '', accountNumber: '', bankName: '' },
    status: doc.status ?? 'PENDING',
    adminNotes: doc.adminNotes,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
};

export const withdrawalsApi = {
  getWithdrawals: async (params?: { page?: number; limit?: number; status?: string }) => {
    const { data, meta } = await getData<any[]>('/users/admin/withdrawals', {
      page: params?.page ?? 1,
      limit: params?.limit ?? 10,
      status: params?.status,
    });

    return {
      success: true,
      withdrawals: (data ?? []).map(mapWithdrawal),
      total: meta?.total ?? 0,
      page: meta?.page ?? params?.page ?? 1,
      limit: meta?.limit ?? params?.limit ?? 10,
    };
  },

  getStats: async () => {
    const { data } = await getData<{
      pending: number;
      approved: number;
      rejected: number;
      paid: number;
      pendingAmount: number;
      paidAmount: number;
    }>('/users/admin/withdrawals/stats');

    return {
      success: true,
      stats: data ?? { pending: 0, approved: 0, rejected: 0, paid: 0, pendingAmount: 0, paidAmount: 0 },
    };
  },

  reviewWithdrawal: async (
    withdrawalId: string,
    data: { status: 'APPROVED' | 'REJECTED' | 'PAID'; notes?: string },
  ) => {
    const response = await apiRequest<any>(`/users/admin/withdrawals/${withdrawalId}/review`, {
      method: 'PUT',
      body: data,
    });

    return {
      success: true,
      withdrawal: response.data ? mapWithdrawal(response.data) : null,
    };
  },
};
