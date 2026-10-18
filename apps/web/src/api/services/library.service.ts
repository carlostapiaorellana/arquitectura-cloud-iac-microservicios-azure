import { apiClient } from '../client';
import type { Book, Loan } from '../../types/api.types';

export const libraryService = {
  /**
   * Obtiene el catálogo de libros bibliográficos en DynamoDB/Cosmos DB con filtro opcional de categoría
   */
  getBooks: async (category?: string): Promise<Book[]> => {
    const params = category && category !== 'ALL' && category.trim() !== '' ? { category } : undefined;
    const response = await apiClient.get<Book[]>('/library/books', { params });
    return response.data;
  },

  /**
   * Obtiene los préstamos activos e históricos de libros del estudiante
   */
  getMyLoans: async (): Promise<Loan[]> => {
    const response = await apiClient.get<Loan[]>('/library/my-loans');
    return response.data;
  },
};
