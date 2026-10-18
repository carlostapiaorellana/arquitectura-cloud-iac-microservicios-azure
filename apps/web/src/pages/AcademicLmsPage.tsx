import React, { useState } from 'react';
import {
  GraduationCap,
  BookOpenCheck,
  Layers,
  MapPin,
  ExternalLink,
  BookOpen,
  AlertCircle,
  RefreshCw,
} from 'lucide-react';
import { useCoursesQuery } from '../hooks/useAcademic';
import { useLmsCoursesQuery } from '../hooks/useLms';
import { CardSkeleton } from '../components/ui/Skeleton';
import { LmsEvaluationsDrawer } from '../components/features/LmsEvaluationsDrawer';
import type { StudentCourseView, Course } from '../types/api.types';

export const AcademicLmsPage: React.FC = () => {
  const [selectedLmsCourse, setSelectedLmsCourse] = useState<StudentCourseView | null>(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

  const coursesQuery = useCoursesQuery();
  const lmsCoursesQuery = useLmsCoursesQuery();

  const handleOpenLms = (course: Course, lmsMatch?: StudentCourseView) => {
    // Si hay un curso correspondiente en el LMS lo usamos; de lo contrario generamos una vista con los datos del curso
    const courseView: StudentCourseView = lmsMatch || {
      enrollmentId: 'ENR-2026-001',
      courseId: course.sercur,
      sectionId: 'SEC-A',
      courseCode: course.sercur,
      title: course.nomcur,
      role: 'STUDENT',
      progressPercentage: 65,
      syllabusUrl: 'https://universidad.edu.pe/syllabus/sis-101.pdf',
      evaluations: [
        {
          evaluationId: 'EVAL-001',
          title: 'Práctica Calificada 1 (Algoritmos)',
          type: 'PRAC',
          weight: 20,
          dueDate: '2026-04-10',
        },
        {
          evaluationId: 'EVAL-002',
          title: 'Examen Parcial Teórico-Práctico',
          type: 'EXAM',
          weight: 40,
          dueDate: '2026-05-15',
        },
      ],
    };

    setSelectedLmsCourse(courseView);
    setIsDrawerOpen(true);
  };

  const isLoading = coursesQuery.isLoading || lmsCoursesQuery.isLoading;
  const isError = coursesQuery.isError && !coursesQuery.data;

  // Mapa de cursos LMS por código para cruce rápido
  const lmsMap = new Map<string, StudentCourseView>();
  if (lmsCoursesQuery.data) {
    for (const lms of lmsCoursesQuery.data) {
      lmsMap.set(lms.courseCode, lms);
    }
  }

  const courses = coursesQuery.data || [];

  return (
    <div className="space-y-6">
      {/* Encabezado */}
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <h2 className="font-display text-xl font-bold text-slate-900 dark:text-white">
            Gestión Académica & Aula Virtual LMS
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Malla curricular vigente, asignaturas inscritas y progreso en el aula virtual NoSQL.
          </p>
        </div>
        <button
          type="button"
          onClick={() => {
            coursesQuery.refetch();
            lmsCoursesQuery.refetch();
          }}
          className="inline-flex items-center gap-1.5 self-start rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 shadow-sm hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-900 dark:text-slate-300"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${isLoading ? 'animate-spin' : ''}`} />
          <span>Actualizar</span>
        </button>
      </div>

      {/* Estado de Error */}
      {isError && (
        <div className="flex items-center gap-3 rounded-xl border border-rose-500/20 bg-rose-500/10 p-4 text-xs text-rose-700 dark:text-rose-400">
          <AlertCircle className="h-5 w-5 flex-shrink-0" />
          <div>
            <p className="font-bold">Error de conexión con el microservicio académico</p>
            <p className="text-[11px] opacity-80">{coursesQuery.error?.message}</p>
          </div>
        </div>
      )}

      {/* Skeletons durante Carga */}
      {isLoading && courses.length === 0 && (
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
        </div>
      )}

      {/* Grid de Asignaturas Curriculares */}
      {!isLoading && courses.length === 0 && (
        <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-slate-300 p-12 text-center dark:border-slate-800">
          <BookOpen className="h-10 w-10 text-slate-400" />
          <h3 className="mt-3 font-display text-sm font-bold text-slate-800 dark:text-slate-200">
            No se encontraron asignaturas registradas
          </h3>
          <p className="mt-1 text-xs text-slate-500">
            El plan curricular para el ciclo actual aún no cuenta con asignaturas activas.
          </p>
        </div>
      )}

      {courses.length > 0 && (
        <div className="grid grid-cols-1 gap-5 md:grid-cols-2 lg:grid-cols-3">
          {courses.map((course) => {
            const lmsMatch = lmsMap.get(course.sercur);
            const progress = lmsMatch ? lmsMatch.progressPercentage : 65;
            const evalCount = lmsMatch?.evaluations?.length ?? 2;

            return (
              <div
                key={course.id}
                className="flex flex-col justify-between rounded-xl border border-slate-200 bg-white p-5 shadow-sm hover:border-brand-blue-300 hover:shadow-md transition-all dark:border-slate-800 dark:bg-slate-900"
              >
                <div className="space-y-3">
                  <div className="flex items-start justify-between gap-3">
                    <div className="rounded-xl bg-brand-blue-500/10 p-3 text-brand-blue-600 dark:text-brand-blue-400">
                      <GraduationCap className="h-6 w-6" />
                    </div>
                    <span className="font-mono text-xs font-bold text-slate-500 dark:text-slate-400 bg-slate-100 dark:bg-slate-800 px-2.5 py-1 rounded-md">
                      {course.sercur}
                    </span>
                  </div>

                  <div>
                    <h3 className="font-display text-sm font-bold text-slate-900 dark:text-white line-clamp-2">
                      {course.nomcur}
                    </h3>
                    <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                      {course.blocur || 'Ciclo Regular'} · Malla Curricular
                    </p>
                  </div>

                  {/* Metadatos: Créditos y Ubicación Física */}
                  <div className="flex flex-wrap items-center gap-2 pt-1 text-xs">
                    <span className="inline-flex items-center gap-1 rounded bg-slate-100 px-2 py-0.5 font-medium text-slate-700 dark:bg-slate-800 dark:text-slate-300">
                      <Layers className="h-3 w-3 text-brand-blue-500" />
                      {course.crecur} Créditos
                    </span>
                    <span className="inline-flex items-center gap-1 rounded bg-slate-100 px-2 py-0.5 font-medium text-slate-700 dark:bg-slate-800 dark:text-slate-300">
                      <MapPin className="h-3 w-3 text-emerald-500" />
                      Aula LAB-01
                    </span>
                  </div>

                  {/* Barra de Progreso LMS */}
                  <div className="space-y-1.5 pt-2">
                    <div className="flex items-center justify-between text-[11px]">
                      <span className="flex items-center gap-1 text-slate-600 dark:text-slate-400 font-medium">
                        <BookOpenCheck className="h-3.5 w-3.5 text-emerald-500" />
                        Avance en LMS
                      </span>
                      <span className="font-mono font-bold text-emerald-600 dark:text-emerald-400">
                        {progress}%
                      </span>
                    </div>
                    <div className="h-2 w-full overflow-hidden rounded-full bg-slate-100 dark:bg-slate-800">
                      <div
                        className="h-full rounded-full bg-gradient-to-r from-emerald-500 to-teal-400 transition-all duration-500"
                        style={{ width: `${progress}%` }}
                      />
                    </div>
                    <span className="block text-[10px] text-slate-400">
                      {evalCount} Evaluaciones Registradas
                    </span>
                  </div>
                </div>

                {/* Botón Aula Virtual */}
                <div className="mt-5 pt-3 border-t border-slate-100 dark:border-slate-800">
                  <button
                    type="button"
                    onClick={() => handleOpenLms(course, lmsMatch)}
                    className="w-full flex items-center justify-center gap-1.5 rounded-lg bg-brand-blue-600/10 px-3 py-2 text-xs font-bold text-brand-blue-600 hover:bg-brand-blue-600 hover:text-white dark:bg-brand-blue-500/20 dark:text-brand-blue-300 dark:hover:bg-brand-blue-600 dark:hover:text-white transition-all active:scale-98"
                  >
                    <span>Aula Virtual LMS</span>
                    <ExternalLink className="h-3.5 w-3.5" />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Drawer Lateral del Aula Virtual */}
      <LmsEvaluationsDrawer
        isOpen={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
        course={selectedLmsCourse}
      />
    </div>
  );
};
