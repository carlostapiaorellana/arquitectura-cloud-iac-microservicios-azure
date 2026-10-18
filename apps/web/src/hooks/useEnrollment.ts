import { useQuery } from '@tanstack/react-query';
import { enrollmentService } from '../api/services/enrollment.service';
import type { Enrollment, Grade } from '../types/api.types';

/**
 * Calcula el promedio ponderado de calificaciones en escala vigesimal (0–20).
 * Si las evaluaciones poseen peso específico se pondera, si no o si el peso suma 0, se aplica promedio simple.
 */
export function calculateWeightedAverage(grades: Grade[]): number {
  if (!grades || grades.length === 0) {
    return 0;
  }

  // Verificar si hay pesos asignados en los objetos de calificación
  let totalScoreWithWeight = 0;
  let totalWeight = 0;
  let hasValidWeights = false;

  for (const grade of grades) {
    const rawWeight = (grade as unknown as { weight?: number }).weight;
    if (typeof rawWeight === 'number' && rawWeight > 0) {
      hasValidWeights = true;
      totalScoreWithWeight += grade.score * rawWeight;
      totalWeight += rawWeight;
    }
  }

  if (hasValidWeights && totalWeight > 0) {
    const weightedAvg = totalScoreWithWeight / totalWeight;
    return Math.round(weightedAvg * 100) / 100;
  }

  // Promedio simple si no hay pesos definidos o suman 0
  const sumScores = grades.reduce((acc, curr) => acc + (curr.score || 0), 0);
  const simpleAvg = sumScores / grades.length;
  return Math.round(simpleAvg * 100) / 100;
}

import { useAuthStore } from '../store/auth.store';

export function useEnrollmentsQuery() {
  const userId = useAuthStore((state) => state.user?.userId);

  return useQuery<Enrollment[], Error>({
    queryKey: ['enrollment', 'my-enrollments', userId ?? 'anonymous'],
    queryFn: enrollmentService.getMyEnrollments,
    enabled: Boolean(userId),
  });
}

export function useGradesQuery() {
  const userId = useAuthStore((state) => state.user?.userId);

  return useQuery<Grade[], Error>({
    queryKey: ['enrollment', 'grades', userId ?? 'anonymous'],
    queryFn: enrollmentService.getGrades,
    enabled: Boolean(userId),
  });
}
