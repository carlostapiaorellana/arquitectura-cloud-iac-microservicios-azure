import { apiClient } from '../client';
import type { UserProfile, UpdateContactRequest } from '../../types/api.types';

export const personService = {
  /**
   * Obtiene la información completa del perfil personal e institucional del usuario autenticado
   */
  getProfile: async (): Promise<UserProfile> => {
    const response = await apiClient.get<UserProfile>('/person/profile/me');
    return response.data;
  },

  /**
   * Actualiza los datos de contacto del usuario (dirección, teléfonos)
   */
  updateContact: async (data: UpdateContactRequest): Promise<{ message: string }> => {
    const response = await apiClient.put<{ message: string }>('/person/profile/me', data);
    return response.data;
  },
};
