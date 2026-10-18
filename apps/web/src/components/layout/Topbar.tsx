import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Sun, Moon, LogOut, User } from 'lucide-react';
import { useThemeStore } from '../../store/theme.store';
import { useAuthStore } from '../../store/auth.store';

const routeNames: Record<string, string> = {
  '/dashboard': 'Dashboard Principal',
  '/academico': 'Gestión Académica & LMS',
  '/matricula-notas': 'Matrícula y Calificaciones',
  '/pagos': 'Tesorería & Pagos',
  '/biblioteca': 'Biblioteca Documental NoSQL',
};

export const Topbar: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { theme, toggleTheme } = useThemeStore();
  const { user, clearSession } = useAuthStore();

  const currentRouteName = routeNames[location.pathname] || 'Portal Estudiantil';

  const handleLogout = () => {
    clearSession();
    navigate('/login', { replace: true });
  };

  return (
    <header className="sticky top-0 z-10 flex h-16 w-full items-center justify-between border-b border-slate-200 bg-white/80 px-6 backdrop-blur-md dark:border-slate-800 dark:bg-slate-900/80">
      {/* Breadcrumbs / Título de Sección */}
      <div className="flex items-center gap-2">
        <span className="text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">
          Portal
        </span>
        <span className="text-slate-300 dark:text-slate-700">/</span>
        <h1 className="font-display text-base font-semibold text-slate-800 dark:text-slate-100">
          {currentRouteName}
        </h1>
      </div>

      {/* Controles de Usuario y Tema */}
      <div className="flex items-center gap-4">
        {/* Toggle Dark / Light Mode */}
        <button
          onClick={toggleTheme}
          aria-label={theme === 'dark' ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'}
          className="flex h-9 w-9 items-center justify-center rounded-lg border border-slate-200 text-slate-600 transition-colors hover:bg-slate-100 hover:text-slate-900 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800 dark:hover:text-white"
        >
          {theme === 'dark' ? (
            <Sun className="h-4 w-4 text-amber-400" />
          ) : (
            <Moon className="h-4 w-4 text-slate-600" />
          )}
        </button>

        {/* Separador vertical */}
        <div className="h-6 w-px bg-slate-200 dark:bg-slate-800" />

        {/* Perfil del Alumno */}
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-brand-blue-100 font-semibold text-brand-blue-700 ring-2 ring-brand-blue-500/20 dark:bg-brand-blue-900/50 dark:text-brand-blue-300">
            {user?.username ? (
              user.username.substring(0, 2).toUpperCase()
            ) : (
              <User className="h-4 w-4" />
            )}
          </div>
          <div className="hidden flex-col text-left md:flex">
            <span className="text-xs font-semibold text-slate-800 dark:text-slate-200">
              {user?.username === 'alu01' ? 'Juan Carlos R.' : user?.username || 'Usuario'}
            </span>
            <span className="flex items-center gap-1 text-[10px] font-medium text-slate-500 dark:text-slate-400">
              <span className="inline-block h-1.5 w-1.5 rounded-full bg-emerald-500" />
              {user?.role || 'STUDENT'}
            </span>
          </div>
        </div>

        {/* Botón Cerrar Sesión */}
        <button
          onClick={handleLogout}
          className="flex items-center gap-1.5 rounded-lg border border-rose-200 bg-rose-50/50 px-3 py-1.5 text-xs font-semibold text-rose-600 transition-colors hover:bg-rose-100 dark:border-rose-900/30 dark:bg-rose-950/20 dark:text-rose-400 dark:hover:bg-rose-900/40"
          title="Cerrar Sesión Segura"
        >
          <LogOut className="h-3.5 w-3.5" />
          <span className="hidden sm:inline">Cerrar Sesión</span>
        </button>
      </div>
    </header>
  );
};
