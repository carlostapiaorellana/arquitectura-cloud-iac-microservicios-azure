import React from 'react';
import {
  FileSpreadsheet,
  CheckCircle2,
  GraduationCap,
  Sparkles,
  Calendar,
  AlertCircle,
  RefreshCw,
} from 'lucide-react';
import {
  useEnrollmentsQuery,
  useGradesQuery,
  calculateWeightedAverage,
} from '../hooks/useEnrollment';
import { GradeBadge } from '../components/ui/GradeBadge';
import { TableRowSkeleton } from '../components/ui/Skeleton';
import { formatDatePE } from '../utils/formatters';

export const EnrollmentGradesPage: React.FC = () => {
  const enrollmentsQuery = useEnrollmentsQuery();
  const gradesQuery = useGradesQuery();

  const isLoading = enrollmentsQuery.isLoading || gradesQuery.isLoading;
  const isError = enrollmentsQuery.isError || gradesQuery.isError;

  const grades = gradesQuery.data || [];
  const enrollments = enrollmentsQuery.data || [];
  const primaryEnrollment = enrollments[0];

  const weightedAverage = calculateWeightedAverage(grades);

  return (
    <div className="space-y-6">
      {/* Encabezado */}
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <h2 className="font-display text-xl font-bold text-slate-900 dark:text-white">
            Ficha de Matrícula & Récord de Calificaciones
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Escala vigesimal peruana (0.00 a 20.00) · Promedio ponderado acumulado en tiempo real.
          </p>
        </div>
        <button
          type="button"
          onClick={() => {
            enrollmentsQuery.refetch();
            gradesQuery.refetch();
          }}
          className="inline-flex items-center gap-1.5 self-start rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 shadow-sm hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-900 dark:text-slate-300"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${isLoading ? 'animate-spin' : ''}`} />
          <span>Actualizar Notas</span>
        </button>
      </div>

      {/* Banner de Promedio Ponderado del Ciclo */}
      <div className="rounded-2xl border border-slate-200 bg-gradient-to-r from-brand-blue-900 via-slate-900 to-indigo-950 p-6 text-white shadow-sm dark:border-slate-800">
        <div className="flex flex-col justify-between gap-4 md:flex-row md:items-center">
          <div className="space-y-2">
            <span className="inline-flex items-center gap-1.5 rounded-full bg-cyan-400/20 px-3 py-0.5 text-xs font-semibold text-cyan-300">
              <Sparkles className="h-3 w-3" /> Rendimiento Académico Vigente
            </span>
            <h3 className="font-display text-xl font-bold">
              Periodo Académico Ordinario 2026-I
            </h3>
            <p className="text-xs text-slate-300">
              Ficha de Matrícula: <span className="font-mono font-semibold text-white">#001</span> · Condición: <span className="font-semibold text-emerald-400">REGULAR / ACTIVO</span>
            </p>
          </div>

          <div className="flex items-center gap-4 rounded-xl bg-white/10 p-4 backdrop-blur-md border border-white/10">
            <div className="rounded-lg bg-emerald-500/20 p-2.5 text-emerald-400">
              <GraduationCap className="h-7 w-7" />
            </div>
            <div>
              <span className="block text-[11px] font-medium text-slate-300 uppercase tracking-wider">
                Promedio Ponderado
              </span>
              <div className="flex items-baseline gap-2">
                <span className="font-display text-3xl font-extrabold tracking-tight text-white">
                  {isLoading ? '...' : weightedAverage.toFixed(2)}
                </span>
                <span className="text-xs text-slate-300">/ 20.00</span>
              </div>
              <div className="mt-1">
                <GradeBadge score={weightedAverage} showScore={false} />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Error */}
      {isError && (
        <div className="flex items-center gap-3 rounded-xl border border-rose-500/20 bg-rose-500/10 p-4 text-xs text-rose-700 dark:text-rose-400">
          <AlertCircle className="h-5 w-5 flex-shrink-0" />
          <span>Error al consultar la ficha de matrícula y notas del estudiante.</span>
        </div>
      )}

      {/* Ficha de Matrícula & Tabla de Calificaciones */}
      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-200 pb-4 dark:border-slate-800">
          <div className="flex items-center gap-3">
            <div className="rounded-xl bg-brand-blue-500/10 p-2.5 text-brand-blue-600 dark:text-brand-blue-400">
              <FileSpreadsheet className="h-5 w-5" />
            </div>
            <div>
              <h3 className="font-display text-sm font-bold text-slate-900 dark:text-white">
                Récord Oficial de Calificaciones del Periodo
              </h3>
              <p className="text-xs text-slate-500">
                {primaryEnrollment
                  ? `Matrícula ID #${primaryEnrollment.id} · Registrada el ${formatDatePE(primaryEnrollment.createdAt)}`
                  : 'Ficha de Matrícula 2026-I · 1 Asignatura Registrada'}
              </p>
            </div>
          </div>
          <span className="self-start sm:self-auto flex items-center gap-1.5 rounded-full bg-emerald-500/10 px-3 py-1 text-xs font-semibold text-emerald-600 dark:text-emerald-400">
            <CheckCircle2 className="h-4 w-4" /> Válida y Acreditada
          </span>
        </div>

        <div className="mt-6 overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="border-b border-slate-200 text-slate-500 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/30">
              <tr>
                <th className="py-3 px-3 font-semibold uppercase tracking-wider">Código Asignatura</th>
                <th className="py-3 px-3 font-semibold uppercase tracking-wider">Evaluación</th>
                <th className="py-3 px-3 font-semibold uppercase tracking-wider">Ponderación</th>
                <th className="py-3 px-3 font-semibold uppercase tracking-wider">Nota Vigesimal</th>
                <th className="py-3 px-3 font-semibold uppercase tracking-wider">Fecha de Calificación</th>
                <th className="py-3 px-3 font-semibold uppercase tracking-wider">Condición</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700 dark:divide-slate-800 dark:text-slate-300">
              {isLoading && grades.length === 0 && (
                <>
                  <TableRowSkeleton columns={6} />
                  <TableRowSkeleton columns={6} />
                </>
              )}

              {!isLoading && grades.length === 0 && (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-500">
                    No se han registrado evaluaciones en el acta de notas aún.
                  </td>
                </tr>
              )}

              {grades.map((grade) => {
                const evalTitle = grade.gradeTypeName || `Evaluación Práctica #${grade.id}`;
                const weight = (grade as unknown as { weight?: number }).weight || 20;

                return (
                  <tr
                    key={grade.id}
                    className="hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors"
                  >
                    <td className="py-3.5 px-3 font-mono font-bold text-slate-900 dark:text-white">
                      SIS-101
                    </td>
                    <td className="py-3.5 px-3 font-medium text-slate-900 dark:text-white">
                      {evalTitle}
                    </td>
                    <td className="py-3.5 px-3 font-mono">
                      <span className="rounded bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                        {weight}%
                      </span>
                    </td>
                    <td className="py-3.5 px-3">
                      <GradeBadge score={grade.score} showLabel={false} />
                    </td>
                    <td className="py-3.5 px-3 text-slate-500 dark:text-slate-400">
                      <span className="inline-flex items-center gap-1">
                        <Calendar className="h-3.5 w-3.5 text-slate-400" />
                        {formatDatePE(grade.gradedAt)}
                      </span>
                    </td>
                    <td className="py-3.5 px-3">
                      <GradeBadge score={grade.score} showScore={false} />
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
