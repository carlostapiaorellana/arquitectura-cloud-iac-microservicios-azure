import axios, { type AxiosRequestConfig, type InternalAxiosRequestConfig } from 'axios';
import { useAuthStore } from '../store/auth.store';
import { generateULID } from '../utils/ulid';
import type { RefreshTokenResponse } from '../types/api.types';

// Determinación segura de la URL base del Gateway (evitando duplicar /api/v1)
const rawBase = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080').replace(/\/+$/, '');
const API_BASE_URL = rawBase.endsWith('/api/v1') ? rawBase : `${rawBase}/api/v1`;

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 15000,
});

// Mutex y cola para resolución ordenada de ráfagas 401
let isRefreshing = false;
interface QueueItem {
  resolve: (token: string) => void;
  reject: (error: unknown) => void;
}
let failedQueue: QueueItem[] = [];

const processQueue = (error: unknown, token: string | null = null) => {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error);
    } else if (token) {
      prom.resolve(token);
    }
  });
  failedQueue = [];
};

// ----------------------------------------------------------------------------
// Request Interceptor: Inyección de Bearer Token y X-Correlation-Id (ULID)
// ----------------------------------------------------------------------------
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // 1. Inyección de token de acceso en memoria
    const token = useAuthStore.getState().accessToken;
    if (token && !config.headers.Authorization) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    // 2. Inyección de X-Correlation-Id monotónico
    if (!config.headers['X-Correlation-Id']) {
      config.headers['X-Correlation-Id'] = generateULID();
    }

    return config;
  },
  (error) => Promise.reject(error)
);

// ----------------------------------------------------------------------------
// Response Interceptor: Mutex de Refresco ante 401 y Cola failedQueue (REV-FE-03)
// ----------------------------------------------------------------------------
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config as AxiosRequestConfig & { _retry?: boolean };

    // Si no es un 401 o la petición ya fue reintentada, rechazar directamente
    if (!error.response || error.response.status !== 401 || originalRequest._retry) {
      return Promise.reject(error);
    }

    // Si el 401 provino del propio endpoint /auth/refresh o /auth/login, no intentar refrescar
    if (
      originalRequest.url?.includes('/auth/refresh') ||
      originalRequest.url?.includes('/auth/login')
    ) {
      useAuthStore.getState().clearSession();
      return Promise.reject(error);
    }

    // Si ya hay un refresco en curso, encolar la promesa
    if (isRefreshing) {
      return new Promise<string>((resolve, reject) => {
        failedQueue.push({ resolve, reject });
      })
        .then((token) => {
          if (originalRequest.headers) {
            originalRequest.headers['Authorization'] = `Bearer ${token}`;
          }
          return apiClient(originalRequest);
        })
        .catch((err) => Promise.reject(err));
    }

    originalRequest._retry = true;
    isRefreshing = true;

    const storedRefreshToken = useAuthStore.getState().refreshToken;
    if (!storedRefreshToken) {
      isRefreshing = false;
      useAuthStore.getState().clearSession();
      if (typeof window !== 'undefined' && window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
      return Promise.reject(error);
    }

    try {
      // REV-FE-03: POST /auth/refresh con JSON payload { refreshToken: storedRefreshToken }
      const refreshResponse = await axios.post<RefreshTokenResponse>(
        `${API_BASE_URL}/auth/refresh`,
        { refreshToken: storedRefreshToken },
        {
          headers: {
            'Content-Type': 'application/json',
            'X-Correlation-Id': generateULID(),
          },
        }
      );

      const newAccessToken = refreshResponse.data.accessToken;
      useAuthStore.getState().setAccessToken(newAccessToken);

      if (refreshResponse.data.refreshToken) {
        // Actualizar sesión si el backend rotó el refresh token
        useAuthStore.getState().setSession(refreshResponse.data);
      }

      // Desbloquear cola con el nuevo token
      processQueue(null, newAccessToken);

      // Reintentar la petición original con el nuevo token
      if (originalRequest.headers) {
        originalRequest.headers['Authorization'] = `Bearer ${newAccessToken}`;
      }
      return apiClient(originalRequest);
    } catch (refreshErr) {
      processQueue(refreshErr, null);
      useAuthStore.getState().clearSession();
      if (typeof window !== 'undefined' && window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
      return Promise.reject(refreshErr);
    } finally {
      isRefreshing = false;
    }
  }
);
