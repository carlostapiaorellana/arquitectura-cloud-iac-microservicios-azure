import { apiClient } from '../client';
import type {
  AuthLoginRequest,
  AuthLoginResponse,
  RefreshTokenRequest,
  RefreshTokenResponse,
} from '../../types/api.types';

export const authService = {
  /**
   * Autenticación institucional en auth-service vía API Gateway
   */
  login: async (credentials: AuthLoginRequest): Promise<AuthLoginResponse> => {
    const response = await apiClient.post<AuthLoginResponse>('/auth/login', credentials);
    return response.data;
  },

  /**
   * Renovación de token de sesión (REV-FE-03)
   */
  refreshToken: async (token: string): Promise<RefreshTokenResponse> => {
    const payload: RefreshTokenRequest = { refreshToken: token };
    const response = await apiClient.post<RefreshTokenResponse>('/auth/refresh', payload);
    return response.data;
  },
};
