import { useAuthStore } from '../../store/authStore';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api';

interface ApiEnvelope<T> {
  success: boolean;
  message: string;
  data?: T;
  errors?: Array<{ field?: string; message: string }>;
  meta?: {
    page?: number;
    limit?: number;
    total?: number;
    totalPages?: number;
  };
}

export class ApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
  }
}

const buildUrl = (path: string, query?: Record<string, string | number | undefined>) => {
  const url = new URL(`${API_BASE_URL}${path}`, window.location.origin);

  Object.entries(query ?? {}).forEach(([key, value]) => {
    if (value !== undefined && value !== '') {
      url.searchParams.set(key, String(value));
    }
  });

  // Return the full URL, not just pathname+search — when API_BASE_URL is
  // an absolute URL (e.g. an ngrok tunnel), dropping the origin here would
  // silently resolve fetch() against window.location.origin instead.
  return url.toString();
};

export async function apiRequest<T>(
  path: string,
  options: Omit<RequestInit, 'body'> & {
    auth?: boolean;
    query?: Record<string, string | number | undefined>;
    body?: unknown;
  } = {},
): Promise<ApiEnvelope<T>> {
  const { auth = true, query, headers, body, ...rest } = options;
  const token = useAuthStore.getState().accessToken;

  const response = await fetch(buildUrl(path, query), {
    ...rest,
    headers: {
      'Content-Type': 'application/json',
      // Without this, ngrok's free-tier interstitial warning page (HTML)
      // is served to browser-originated requests instead of proxying to
      // the backend, since it detects a browser User-Agent.
      'ngrok-skip-browser-warning': 'true',
      ...(auth && token ? { Authorization: `Bearer ${token}` } : {}),
      ...(headers ?? {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  let payload: ApiEnvelope<T> | null = null;
  try {
    payload = (await response.json()) as ApiEnvelope<T>;
  } catch {
    payload = null;
  }

  if (!response.ok) {
    if (response.status === 401) {
      useAuthStore.getState().logout();
    }
    throw new ApiError(
      payload?.message || `Request failed with status ${response.status}`,
      response.status,
    );
  }

  return payload ?? { success: true, message: 'Success' };
}

export const getData = async <T>(
  path: string,
  query?: Record<string, string | number | undefined>,
) => {
  const response = await apiRequest<T>(path, { method: 'GET', query });
  return {
    data: response.data,
    meta: response.meta,
    message: response.message,
  };
};
