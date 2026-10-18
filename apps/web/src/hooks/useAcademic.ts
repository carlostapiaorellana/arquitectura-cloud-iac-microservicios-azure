import { useQuery } from '@tanstack/react-query';
import { academicService } from '../api/services/academic.service';
import type { Course, Section } from '../types/api.types';

export function useCoursesQuery() {
  return useQuery<Course[], Error>({
    queryKey: ['academic', 'courses'],
    queryFn: academicService.getCourses,
    staleTime: 10 * 60 * 1000, // 10 minutos de frescura para catálogo curricular
  });
}

export function useSectionsQuery() {
  return useQuery<Section[], Error>({
    queryKey: ['academic', 'sections'],
    queryFn: academicService.getSections,
  });
}
