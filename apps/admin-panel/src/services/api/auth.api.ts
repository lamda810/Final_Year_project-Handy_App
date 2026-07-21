/**
 * Auth API — local backend authentication for admin panel.
 */
import { apiRequest } from './client';
import { useAuthStore } from '../../store/authStore';

export const authApi = {
  // `identifier` is whatever the user typed — either a phone number or an
  // email — matching the backend's login endpoint, which accepts either.
  login: async (identifier: string, password: string) => {
    const isEmail = identifier.includes('@');

    const response = await apiRequest<{
      user: {
        id: string;
        phone: string;
        email?: string;
        role: string;
        isVerified: boolean;
        isActive?: boolean;
      };
      accessToken: string;
      refreshToken: string;
    }>('/auth/login', {
      method: 'POST',
      auth: false,
      body: isEmail
        ? { email: identifier, password }
        : { phone: identifier, password },
    });

    const payload = response.data;
    if (!payload) {
      throw new Error('Login failed');
    }

    if (payload.user.role !== 'ADMIN') {
      throw new Error('This account does not have admin privileges');
    }

    const userData = {
      _id: payload.user.id,
      phone: payload.user.phone || identifier,
      email: payload.user.email,
      role: payload.user.role,
      isVerified: payload.user.isVerified,
      isActive: payload.user.isActive ?? true,
    };

    return {
      success: true,
      user: userData,
      accessToken: payload.accessToken,
      refreshToken: payload.refreshToken,
    };
  },

  logout: async () => {
    try {
      const refreshToken = useAuthStore.getState().refreshToken;
      await apiRequest('/auth/logout', {
        method: 'POST',
        body: refreshToken ? { refreshToken } : {},
      });
    } catch {
      // Ignore logout errors during local development
    }
    useAuthStore.getState().logout();
  },
};
