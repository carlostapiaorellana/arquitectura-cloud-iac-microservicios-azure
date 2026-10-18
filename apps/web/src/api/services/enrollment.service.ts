import { apiClient } from '../client';
import type { Enrollment, Grade } from '../../types/api.types';

export const enrollmentService = {
  /**
   * Obtiene las fichas de matrícula registradas del estudiante autenticado
   */
  getMyEnrollments: async (): Promise<Enrollment[]> => {
    const response = await apiClient.get<Enrollment[]>('/enrollment/my-enrollments');
    return response.data;
  },

  /**
   * Obtiene el récord de calificaciones vigesimales del estudiante
   */
  getGrades: async (): Promise<Grade[]> => {
    const response = await apiClient.get<Grade[]>('/enrollment/grades');
    return response.data;
  },
};
