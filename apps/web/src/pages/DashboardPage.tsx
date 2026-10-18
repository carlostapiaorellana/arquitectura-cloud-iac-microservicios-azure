import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/auth.store';
import { useProfileQuery } from '../hooks/useProfile';
import { useGradesQuery, calculateWeightedAverage } from '../hooks/useEnrollment';
import { useOrdersQuery } from '../hooks/useFinance';
import { useMyLoansQuery } from '../hooks/useLibrary';
import { EditContactModal } from '../components/features/EditContactModal';
import { Skeleton } from '../components/ui/Skeleton';
import { formatPEN } from '../utils/formatters';
import {
  GraduationCap,
  BookOpen,
  CreditCard,
  Layers,
  Sparkles,
  Server,
  Zap,
  Edit3,
  Phone,
  MapPin,
  ArrowRight,
  ShieldCheck,
} from 'lucide-react';

export const DashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuthStore();
  const [isEditContactOpen, setIsEditContactOpen] = useState(false);

  // Queries reactivas a los microservicios
  const profileQuery = useProfileQuery();
  const gradesQuery = useGradesQuery();
  const ordersQuery = useOrdersQuery();
  const loansQuery = useMyLoansQuery();

  const profile = profileQuery.data;
  const grades = gradesQuery.data || [];
  const orders = ordersQuery.data || [];
  const loans = loansQuery.data || [];

  // Cálculos dinámicos
  const weightedAverage = calculateWeightedAverage(grades);

  const pendingOrders = orders.filter(
    (o) =>
      o.statusCode === 'PENDING' ||
      o.statusId === 1 ||
      (o.statusName && o.statusName.toUpperCase().includes('PEND'))
  );
  const pendingAmount = pendingOrders.reduce((sum, o) => sum + (o.amount || 0), 0);

  const studentFullName =
    profile?.fullName ||
    (profile?.firstName ? `${profile.firstName} ${profile.lastNameFather || ''}`.trim() : null) ||
    (profileQuery.isLoading ? 'Cargando perfil...' : user?.username || 'Estudiante');

  const institutionalCode =
    profile?.institutionalCode ||
    (profileQuery.isLoading ? 'Cargando...' : user?.username ? `ALU-${user.username.toUpperCase()}` : 'ALU-REG-2026');

  return (
    <div className="space-y-6">
      {/* Banner de Bienvenida y Perfil */}
      <div className="rounded-2xl border border-slate-200 bg-gradient-to-r from-brand-blue-900 via-brand-blue-800 to-slate-900 p-6 text-white shadow-sm dark:border-slate-800">
        <div className="flex flex-col justify-between gap-4 lg:flex-row lg:items-center">
          <div className="space-y-2">
            <span className="inline-flex items-center gap-1.5 rounded-full bg-cyan-400/20 px-3 py-0.5 text-xs font-semibold text-cyan-300">
              <Sparkles className="h-3 w-3" /> Periodo Activo 2026-I
            </span>
            <h2 className="font-display text-2xl font-bold tracking-tight">
              Bienvenido, {studentFullName}
            </h2>
            <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-slate-300">
              <p>
                Código Institucional: <span className="font-mono font-semibold text-white">{institutionalCode}</span>
              </p>
              <span>·</span>
              <p>
                Programa: <span className="font-medium text-white">Ingeniería de Sistemas</span>
              </p>
              {profile?.address && (
                <>
                  <span>·</span>
                  <p className="flex items-center gap-1 text-slate-300">
                    <MapPin className="h-3 w-3 text-cyan-400" />
                    <span>{profile.address}</span>
                  </p>
                </>
              )}
              {profile?.mobile && (
                <>
                  <span>·</span>
                  <p className="flex items-center gap-1 text-slate-300">
                    <Phone className="h-3 w-3 text-cyan-400" />
                    <span>{profile.mobile}</span>
                  </p>
                </>
              )}
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <button
              type="button"
              onClick={() => setIsEditContactOpen(true)}
              className="flex items-center gap-1.5 rounded-xl bg-white/10 px-3.5 py-2 text-xs font-semibold text-white backdrop-blur-md hover:bg-white/20 active:scale-95 transition-all"
            >
              <Edit3 className="h-4 w-4 text-cyan-300" />
              <span>Editar Datos</span>
            </button>

            <div className="flex items-center gap-2 rounded-xl bg-white/10 px-4 py-2 backdrop-blur-md">
              <Zap className="h-5 w-5 text-amber-400" />
              <div className="text-xs">
                <span className="block text-slate-300">Estado de Matrícula</span>
                <span className="font-bold text-emerald-400">REGULAR / ACTIVO</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Grid de 4 KPIs Interactivos con Navegación */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {/* KPI 1: Promedio Ponderado -> /matricula-notas */}
        <div
          onClick={() => navigate('/matricula-notas')}
          className="group cursor-pointer rounded-xl border border-slate-200 bg-white p-5 shadow-sm hover:border-brand-blue-400 hover:shadow-md transition-all active:scale-98 dark:border-slate-800 dark:bg-slate-900"
          role="button"
          tabIndex={0}
          onKeyDown={(e) => e.key === 'Enter' && navigate('/matricula-notas')}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400">
              Promedio Ponderado
            </span>
            <div className="rounded-lg bg-emerald-500/10 p-2 text-emerald-600 dark:text-emerald-400 group-hover:scale-110 transition-transform">
              <GraduationCap className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            {gradesQuery.isLoading ? (
              <Skeleton className="h-8 w-20" />
            ) : (
              <>
                <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
                  {weightedAverage > 0 ? weightedAverage.toFixed(2) : grades.length > 0 ? '0.00' : 'S/C'}
                </span>
                <span className="text-xs text-slate-500">/ 20.00</span>
              </>
            )}
          </div>
          <div className="mt-1 flex items-center justify-between">
            <span className="text-[11px] font-semibold text-emerald-600 dark:text-emerald-400">
              {weightedAverage >= 10.5 ? 'Escala Vigesimal: APROBADO' : weightedAverage > 0 ? 'Escala Vigesimal: DESAPROBADO' : 'Sin Calificaciones'}
            </span>
            <ArrowRight className="h-3.5 w-3.5 text-slate-400 opacity-0 group-hover:opacity-100 group-hover:translate-x-1 transition-all" />
          </div>
        </div>

        {/* KPI 2: Malla & LMS -> /academico */}
        <div
          onClick={() => navigate('/academico')}
          className="group cursor-pointer rounded-xl border border-slate-200 bg-white p-5 shadow-sm hover:border-brand-blue-400 hover:shadow-md transition-all active:scale-98 dark:border-slate-800 dark:bg-slate-900"
          role="button"
          tabIndex={0}
          onKeyDown={(e) => e.key === 'Enter' && navigate('/academico')}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400">
              Créditos Inscritos
            </span>
            <div className="rounded-lg bg-brand-blue-500/10 p-2 text-brand-blue-600 dark:text-brand-blue-400 group-hover:scale-110 transition-transform">
              <Layers className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              {grades.length > 0 ? grades.length * 4 : 4}
            </span>
            <span className="text-xs text-slate-500">Créditos</span>
          </div>
          <div className="mt-1 flex items-center justify-between">
            <span className="text-[11px] font-medium text-slate-500">
              {grades.length > 0 ? `${grades.length} Asignatura(s)` : '1 Asignatura en Curso'}
            </span>
            <ArrowRight className="h-3.5 w-3.5 text-slate-400 opacity-0 group-hover:opacity-100 group-hover:translate-x-1 transition-all" />
          </div>
        </div>

        {/* KPI 3: Tesorería -> /pagos */}
        <div
          onClick={() => navigate('/pagos')}
          className="group cursor-pointer rounded-xl border border-slate-200 bg-white p-5 shadow-sm hover:border-amber-400 hover:shadow-md transition-all active:scale-98 dark:border-slate-800 dark:bg-slate-900"
          role="button"
          tabIndex={0}
          onKeyDown={(e) => e.key === 'Enter' && navigate('/pagos')}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400">
              Estado de Tesorería
            </span>
            <div className="rounded-lg bg-amber-500/10 p-2 text-amber-600 dark:text-amber-400 group-hover:scale-110 transition-transform">
              <CreditCard className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            {ordersQuery.isLoading ? (
              <Skeleton className="h-8 w-24" />
            ) : (
              <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
                {formatPEN(pendingAmount)}
              </span>
            )}
          </div>
          <div className="mt-1 flex items-center justify-between">
            <span className="text-[11px] font-semibold text-amber-600 dark:text-amber-400">
              {pendingOrders.length > 0
                ? `${pendingOrders.length} Orden(es) Pendiente(s)`
                : 'Al día en Tesorería'}
            </span>
            <ArrowRight className="h-3.5 w-3.5 text-slate-400 opacity-0 group-hover:opacity-100 group-hover:translate-x-1 transition-all" />
          </div>
        </div>

        {/* KPI 4: Biblioteca Virtual -> /biblioteca */}
        <div
          onClick={() => navigate('/biblioteca')}
          className="group cursor-pointer rounded-xl border border-slate-200 bg-white p-5 shadow-sm hover:border-cyan-400 hover:shadow-md transition-all active:scale-98 dark:border-slate-800 dark:bg-slate-900"
          role="button"
          tabIndex={0}
          onKeyDown={(e) => e.key === 'Enter' && navigate('/biblioteca')}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400">
              Biblioteca Virtual NoSQL
            </span>
            <div className="rounded-lg bg-brand-accent/10 p-2 text-cyan-600 dark:text-cyan-400 group-hover:scale-110 transition-transform">
              <BookOpen className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            {loansQuery.isLoading ? (
              <Skeleton className="h-8 w-16" />
            ) : (
              <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
                {loans.length}
              </span>
            )}
            <span className="text-xs text-slate-500">Préstamo(s) Activo(s)</span>
          </div>
          <div className="mt-1 flex items-center justify-between">
            <span className="text-[11px] font-medium text-emerald-600 dark:text-emerald-400">
              Sin Multas Registradas
            </span>
            <ArrowRight className="h-3.5 w-3.5 text-slate-400 opacity-0 group-hover:opacity-100 group-hover:translate-x-1 transition-all" />
          </div>
        </div>
      </div>

      {/* Tarjeta de Arquitectura y Microservicios Conectados */}
      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Server className="h-5 w-5 text-brand-blue-500" />
            <h3 className="font-display text-sm font-bold text-slate-900 dark:text-white">
              Ecosistema Integral de Microservicios Conectado (Fase 2)
            </h3>
          </div>
          <span className="inline-flex items-center gap-1 rounded-full bg-emerald-500/10 px-2.5 py-0.5 text-xs font-semibold text-emerald-600 dark:text-emerald-400">
            <ShieldCheck className="h-3.5 w-3.5" /> 7 Microservicios en Línea
          </span>
        </div>
        <p className="mt-2 text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
          La plataforma integra de extremo a extremo: autenticación JWT asimétrica RS256/JWKS (<code className="text-brand-blue-600 dark:text-brand-blue-400">auth-service</code>),
          padrón institucional (<code className="text-brand-blue-600 dark:text-brand-blue-400">person-service</code>), gestión curricular (<code className="text-brand-blue-600 dark:text-brand-blue-400">academic-service</code>),
          matrículas y calificaciones vigesimales (<code className="text-brand-blue-600 dark:text-brand-blue-400">enrollment-service</code>), tesorería con pasarela e idempotencia en Redis 7 (<code className="text-brand-blue-600 dark:text-brand-blue-400">finance-service</code>),
          y catálogos documentales NoSQL en DynamoDB / Azure Cosmos DB (<code className="text-brand-blue-600 dark:text-brand-blue-400">library-service</code> y <code className="text-brand-blue-600 dark:text-brand-blue-400">lms-service</code>).
        </p>
      </div>

      {/* Modal para Editar Datos de Contacto */}
      <EditContactModal
        isOpen={isEditContactOpen}
        onClose={() => setIsEditContactOpen(false)}
        initialData={profile}
      />
    </div>
  );
};
