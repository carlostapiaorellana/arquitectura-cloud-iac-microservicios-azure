import { useQuery } from '@tanstack/react-query';
import { lmsService } from '../api/services/lms.service';
import type { StudentCourseView, LmsEvaluation } from '../types/api.types';

import { useAuthStore } from '../store/auth.store';

export function useLmsCoursesQuery() {
  const userId = useAuthStore((state) => state.user?.userId);

  return useQuery<StudentCourseView[], Error>({
    queryKey: ['lms', 'my-courses', userId ?? 'anonymous'],
    queryFn: lmsService.getMyCourses,
    enabled: Boolean(userId),
  });
}

export function useEvaluationsQuery(courseId: string) {
  return useQuery<LmsEvaluation[], Error>({
    queryKey: ['lms', 'evaluations', courseId],
    queryFn: () => lmsService.getEvaluations(courseId),
    enabled: Boolean(courseId && courseId.trim() !== ''),
  });
}
