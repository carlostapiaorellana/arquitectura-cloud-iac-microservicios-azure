import { apiClient } from '../client';
import type { StudentCourseView, LmsEvaluation } from '../../types/api.types';

export const lmsService = {
  /**
   * Obtiene la vista de cursos matriculados en el LMS NoSQL del estudiante con avance y evaluaciones
   */
  getMyCourses: async (): Promise<StudentCourseView[]> => {
    const response = await apiClient.get<StudentCourseView[]>('/lms/my-courses');
    return response.data;
  },

  /**
   * Obtiene las evaluaciones programadas y ponderadas de un curso específico en el LMS
   */
  getEvaluations: async (courseId: string): Promise<LmsEvaluation[]> => {
    const response = await apiClient.get<LmsEvaluation[]>(`/lms/courses/${encodeURIComponent(courseId)}/evaluations`);
    return response.data;
  },
};
