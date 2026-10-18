import React, { useEffect, useState } from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  GraduationCap,
  FileSpreadsheet,
  CreditCard,
  BookOpen,
  ChevronLeft,
  ChevronRight,
  ShieldCheck,
  Server,
} from 'lucide-react';
import { cn } from '../../utils/cn';

interface SidebarProps {
  collapsed: boolean;
  onToggleCollapse: () => void;
}

interface NavItem {
  name: string;
  path: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: string;
}

const navItems: NavItem[] = [
  { name: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
  { name: 'Académico & LMS', path: '/academico', icon: GraduationCap },
  { name: 'Matrícula y Notas', path: '/matricula-notas', icon: FileSpreadsheet },
  { name: 'Tesorería y Pagos', path: '/pagos', icon: CreditCard },
  { name: 'Biblioteca NoSQL', path: '/biblioteca', icon: BookOpen },
];

export const Sidebar: React.FC<SidebarProps> = ({ collapsed, onToggleCollapse }) => {
  const [gatewayOnline, setGatewayOnline] = useState<boolean>(true);

  // Comprobar estado de salud del Gateway perimetral
  useEffect(() => {
    let isMounted = true;
    const checkGateway = async () => {
      try {
        const res = await fetch('http://localhost:8080/health', { method: 'GET' });
        if (isMounted) setGatewayOnline(res.ok);
      } catch {
        if (isMounted) setGatewayOnline(false);
      }
    };

    checkGateway();
    const interval = setInterval(checkGateway, 20000);
    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, []);

  return (
    <aside
      className={cn(
        'relative flex flex-col border-r border-slate-200 bg-white transition-all duration-300 dark:border-slate-800 dark:bg-slate-900',
        collapsed ? 'w-20' : 'w-64'
      )}
    >
      {/* Botón flotante para colapsar/expandir */}
      <button
        onClick={onToggleCollapse}
        aria-label={collapsed ? 'Expandir barra lateral' : 'Colapsar barra lateral'}
        className="absolute -right-3 top-7 z-20 flex h-6 w-6 items-center justify-center rounded-full border border-slate-200 bg-white shadow-sm transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:hover:bg-slate-700"
      >
        {collapsed ? (
          <ChevronRight className="h-3.5 w-3.5 text-slate-600 dark:text-slate-300" />
        ) : (
          <ChevronLeft className="h-3.5 w-3.5 text-slate-600 dark:text-slate-300" />
        )}
      </button>

      {/* Cabecera con Escudo UNFPG */}
      <div className="flex h-16 items-center px-4">
        <div className="flex items-center gap-3 overflow-hidden">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-brand-blue-700 to-brand-blue-900 text-white shadow-md">
            <ShieldCheck className="h-6 w-6 text-brand-accent" />
          </div>
          {!collapsed && (
            <div className="flex flex-col truncate">
              <span className="font-display text-sm font-bold tracking-tight text-slate-900 dark:text-white">
                UNFPG PORTAL
              </span>
              <span className="text-[11px] font-medium text-slate-500 dark:text-slate-400">
                Plataforma Cloud-Native
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Navegación Principal */}
      <nav className="flex-1 space-y-1.5 px-3 py-4">
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                cn(
                  'group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-200',
                  isActive
                    ? 'bg-brand-blue-50 text-brand-blue-600 shadow-sm dark:bg-brand-blue-900/30 dark:text-brand-blue-400'
                    : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-800/60 dark:hover:text-slate-200'
                )
              }
              title={collapsed ? item.name : undefined}
            >
              <Icon className="h-5 w-5 shrink-0 transition-transform group-hover:scale-105" />
              {!collapsed && (
                <span className="truncate">{item.name}</span>
              )}
            </NavLink>
          );
        })}
      </nav>

      {/* Footer de Estado: Gateway UP */}
      <div className="border-t border-slate-200 p-3 dark:border-slate-800">
        <div
          className={cn(
            'flex items-center gap-2.5 rounded-lg border px-3 py-2 transition-colors',
            gatewayOnline
              ? 'border-emerald-500/20 bg-emerald-50/50 text-emerald-700 dark:bg-emerald-950/20 dark:text-emerald-400'
              : 'border-rose-500/20 bg-rose-50/50 text-rose-700 dark:bg-rose-950/20 dark:text-rose-400'
          )}
        >
          <Server className="h-4 w-4 shrink-0" />
          {!collapsed && (
            <div className="flex flex-1 items-center justify-between overflow-hidden">
              <span className="text-xs font-medium">Gateway :8080</span>
              <span className="flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-wider">
                <span
                  className={cn(
                    'h-2 w-2 rounded-full',
                    gatewayOnline ? 'animate-pulse bg-emerald-500' : 'bg-rose-500'
                  )}
                />
                {gatewayOnline ? 'UP' : 'DOWN'}
              </span>
            </div>
          )}
        </div>
      </div>
    </aside>
  );
};
