import { apiClient } from '../client';
import type { Course, Section, Program } from '../../types/api.types';

export const academicService = {
  /**
   * Obtiene el listado completo de asignaturas curriculares
   */
  getCourses: async (): Promise<Course[]> => {
    const response = await apiClient.get<Course[]>('/academic/courses');
    return response.data;
  },

  /**
   * Obtiene las secciones académicas activas del periodo
   */
  getSections: async (): Promise<Section[]> => {
    const response = await apiClient.get<Section[]>('/academic/sections');
    return response.data;
  },

  /**
   * Obtiene los programas académicos (carreras) disponibles
   */
  getPrograms: async (): Promise<Program[]> => {
    const response = await apiClient.get<Program[]>('/academic/programs');
    return response.data;
  },
};
