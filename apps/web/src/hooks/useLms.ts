import { useQuery } from '@tanstack/react-query';
import { lmsService } from '../api/services/lms.service';
import type { StudentCourseView, LmsEvaluation } from '../types/api.types';

export function useLmsCoursesQuery() {
  return useQuery<StudentCourseView[], Error>({
    queryKey: ['lms', 'my-courses'],
    queryFn: lmsService.getMyCourses,
  });
}

export function useEvaluationsQuery(courseId: string) {
  return useQuery<LmsEvaluation[], Error>({
    queryKey: ['lms', 'evaluations', courseId],
    queryFn: () => lmsService.getEvaluations(courseId),
    enabled: Boolean(courseId && courseId.trim() !== ''),
  });
}
