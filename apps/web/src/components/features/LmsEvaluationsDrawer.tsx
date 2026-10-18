import React, { useEffect } from 'react';
import {
  X,
  FileText,
  ExternalLink,
  Calendar,
  Layers,
  Award,
  AlertCircle,
} from 'lucide-react';
import { useEvaluationsQuery } from '../../hooks/useLms';
import { Skeleton } from '../ui/Skeleton';
import { formatDatePE } from '../../utils/formatters';
import type { StudentCourseView, LmsEvaluation } from '../../types/api.types';

export interface LmsEvaluationsDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  course: StudentCourseView | null;
}

export const LmsEvaluationsDrawer: React.FC<LmsEvaluationsDrawerProps> = ({
  isOpen,
  onClose,
  course,
}) => {
  const evaluationsQuery = useEvaluationsQuery(course?.courseId || '');

  // Bloqueo de scroll de fondo y soporte tecla Esc
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      window.addEventListener('keydown', handleKeyDown);
    }
    return () => {
      document.body.style.overflow = 'unset';
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen, onClose]);

  if (!isOpen || !course) return null;

  // Unir evaluaciones de query si existen o del curso como fallback
  const evaluations: LmsEvaluation[] =
    evaluationsQuery.data && evaluationsQuery.data.length > 0
      ? evaluationsQuery.data
      : course.evaluations || [];

  const getEvaluationTypeBadge = (type: string) => {
    switch (type.toUpperCase()) {
      case 'EXAM':
        return 'bg-purple-500/10 text-purple-600 dark:text-purple-400 border border-purple-500/20';
      case 'PRAC':
        return 'bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-500/20';
      case 'LAB':
        return 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20';
      case 'PROJ':
        return 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20';
      default:
        return 'bg-slate-500/10 text-slate-600 dark:text-slate-400 border border-slate-500/20';
    }
  };

  const getEvaluationTypeLabel = (type: string) => {
    switch (type.toUpperCase()) {
      case 'EXAM':
        return 'Examen Parcial / Final';
      case 'PRAC':
        return 'Práctica Calificada';
      case 'LAB':
        return 'Laboratorio Práctico';
      case 'PROJ':
        return 'Proyecto de Curso';
      default:
        return type;
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex justify-end backdrop-blur-sm bg-black/50 transition-opacity animate-in fade-in duration-200"
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          onClose();
        }
      }}
      role="dialog"
      aria-modal="true"
      aria-labelledby="lms-drawer-title"
    >
      <div
        className="w-full max-w-lg h-full bg-white dark:bg-slate-900 border-l border-slate-200 dark:border-slate-800 shadow-2xl flex flex-col transform transition-transform animate-in slide-in-from-right duration-300"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Cabecera del Drawer */}
        <div className="flex items-start justify-between border-b border-slate-200 p-6 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/30">
          <div className="space-y-1 pr-4">
            <div className="flex items-center gap-2">
              <span className="font-mono text-xs font-bold text-brand-blue-600 dark:text-brand-blue-400 bg-brand-blue-500/10 px-2 py-0.5 rounded">
                {course.courseCode}
              </span>
              <span className="text-[11px] text-slate-500">Sección: {course.sectionId}</span>
            </div>
            <h2
              id="lms-drawer-title"
              className="font-display text-base font-bold text-slate-900 dark:text-white"
            >
              {course.title}
            </h2>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Rol de Acceso: <span className="font-semibold text-slate-700 dark:text-slate-300">{course.role}</span>
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-2 text-slate-400 hover:bg-slate-200/60 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-200 transition-colors"
            aria-label="Cerrar panel"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Contenido con Scroll */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* Barra de Progreso del Curso */}
          <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900/60 space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="font-semibold text-slate-700 dark:text-slate-300">
                Progreso del Semestre en LMS
              </span>
              <span className="font-mono font-bold text-brand-blue-600 dark:text-brand-blue-400">
                {course.progressPercentage}%
              </span>
            </div>
            <div className="h-2.5 w-full overflow-hidden rounded-full bg-slate-100 dark:bg-slate-800">
              <div
                className="h-full rounded-full bg-gradient-to-r from-brand-blue-500 to-cyan-400 transition-all duration-500"
                style={{ width: `${Math.min(100, Math.max(0, course.progressPercentage))}%` }}
              />
            </div>
            <p className="text-[11px] text-slate-400">
              Contenido curricular sincronizado con Azure Cosmos DB / DynamoDB.
            </p>
          </div>

          {/* Enlace al Syllabus PDF */}
          <div className="flex items-center justify-between rounded-xl border border-slate-200/90 bg-slate-50 p-4 dark:border-slate-800 dark:bg-slate-800/40">
            <div className="flex items-center gap-3">
              <div className="rounded-lg bg-rose-500/10 p-2 text-rose-600 dark:text-rose-400">
                <FileText className="h-5 w-5" />
              </div>
              <div>
                <h4 className="text-xs font-bold text-slate-900 dark:text-white">
                  Syllabus Oficial de la Asignatura
                </h4>
                <p className="text-[11px] text-slate-500">Plan de estudios y competencias en PDF</p>
              </div>
            </div>
            <a
              href={course.syllabusUrl || '#syllabus'}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-1 rounded-lg bg-white border border-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-700 shadow-sm hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200"
            >
              <span>Ver PDF</span>
              <ExternalLink className="h-3.5 w-3.5 text-slate-400" />
            </a>
          </div>

          {/* Evaluaciones Programadas */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Layers className="h-4 w-4 text-brand-blue-500" />
                <h3 className="font-display text-sm font-bold text-slate-900 dark:text-white">
                  Evaluaciones del Aula Virtual
                </h3>
              </div>
              <span className="text-xs text-slate-400">
                {evaluations.length} evaluacion(es)
              </span>
            </div>

            {/* Estado de carga */}
            {evaluationsQuery.isLoading && evaluations.length === 0 && (
              <div className="space-y-3">
                <Skeleton className="h-20 w-full rounded-xl" />
                <Skeleton className="h-20 w-full rounded-xl" />
              </div>
            )}

            {/* Error */}
            {evaluationsQuery.isError && evaluations.length === 0 && (
              <div className="rounded-xl border border-rose-500/20 bg-rose-500/10 p-4 text-xs text-rose-700 dark:text-rose-400 flex items-center gap-2">
                <AlertCircle className="h-4 w-4 flex-shrink-0" />
                <span>Error al sincronizar evaluaciones con el microservicio LMS.</span>
              </div>
            )}

            {/* Lista de Evaluaciones */}
            {!evaluationsQuery.isLoading && evaluations.length === 0 ? (
              <div className="rounded-xl border border-dashed border-slate-300 p-8 text-center text-xs text-slate-500 dark:border-slate-700">
                No hay evaluaciones programadas actualmente para este curso.
              </div>
            ) : (
              <div className="space-y-3">
                {evaluations.map((evalItem) => (
                  <div
                    key={evalItem.evaluationId}
                    className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm hover:border-brand-blue-300 transition-colors dark:border-slate-800 dark:bg-slate-900"
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="space-y-1">
                        <span
                          className={`inline-block rounded-full px-2 py-0.5 text-[10px] font-bold ${getEvaluationTypeBadge(
                            evalItem.type
                          )}`}
                        >
                          {getEvaluationTypeLabel(evalItem.type)}
                        </span>
                        <h4 className="text-xs font-bold text-slate-900 dark:text-white">
                          {evalItem.title}
                        </h4>
                      </div>
                      <div className="flex items-center gap-1 rounded-md bg-slate-100 px-2 py-1 text-[11px] font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-300">
                        <Award className="h-3 w-3 text-brand-blue-500" />
                        <span>Peso: {evalItem.weight}%</span>
                      </div>
                    </div>

                    <div className="mt-3 flex items-center justify-between border-t border-slate-100 pt-3 text-[11px] text-slate-500 dark:border-slate-800/80">
                      <span className="flex items-center gap-1">
                        <Calendar className="h-3 w-3 text-slate-400" />
                        Entrega: <span className="font-medium text-slate-700 dark:text-slate-300">{formatDatePE(evalItem.dueDate)}</span>
                      </span>
                      <span className="font-mono text-[10px] text-slate-400">
                        ID: {evalItem.evaluationId}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Pie del Drawer */}
        <div className="border-t border-slate-200 p-4 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/30 flex justify-end">
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg bg-slate-200 dark:bg-slate-800 px-4 py-2 text-xs font-semibold text-slate-700 dark:text-slate-200 hover:bg-slate-300 dark:hover:bg-slate-700 transition-colors"
          >
            Cerrar Aula Virtual
          </button>
        </div>
      </div>
    </div>
  );
};
