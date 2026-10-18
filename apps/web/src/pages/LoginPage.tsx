import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  ShieldCheck,
  Eye,
  EyeOff,
  Sparkles,
  Server,
  KeyRound,
  User,
  AlertCircle,
  Copy,
  Check,
  Loader2,
  Lock,
} from 'lucide-react';
import { useAuthStore } from '../store/auth.store';
import { authService } from '../api/services/auth.service';
import type { ApiErrorEnvelope } from '../types/api.types';
import axios from 'axios';

export const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const setSession = useAuthStore((state) => state.setSession);

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorDetails, setErrorDetails] = useState<{
    code: string;
    message: string;
    correlationId: string;
  } | null>(null);
  const [copiedCorrId, setCopiedCorrId] = useState(false);

  // Destino posterior al login
  const fromLocation = (location.state as { from?: { pathname: string } })?.from?.pathname || '/dashboard';

  const handleFillDemo = () => {
    setUsername('alu01');
    setPassword('password123');
    setErrorDetails(null);
  };

  const handleCopyCorrId = () => {
    if (errorDetails?.correlationId) {
      navigator.clipboard.writeText(errorDetails.correlationId);
      setCopiedCorrId(true);
      setTimeout(() => setCopiedCorrId(false), 2000);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!username.trim() || !password.trim()) return;

    setIsLoading(true);
    setErrorDetails(null);

    try {
      const response = await authService.login({ username, password });
      setSession(response);
      navigate(fromLocation, { replace: true });
    } catch (err: unknown) {
      let code = 'AUTH_ERROR';
      let message = 'Error de conexión con el servicio de autenticación.';
      let correlationId = 'N/A';

      if (axios.isAxiosError(err) && err.response?.data) {
        const envelope = err.response.data as ApiErrorEnvelope;
        if (envelope.error) {
          code = envelope.error.code || 'UNAUTHENTICATED';
          message = envelope.error.message || 'Credenciales inválidas.';
          correlationId = envelope.error.correlationId || (err.response.headers['x-correlation-id'] as string) || 'N/A';
        }
      } else if (err instanceof Error) {
        message = err.message;
      }

      setErrorDetails({ code, message, correlationId });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen w-full bg-slate-50 dark:bg-slate-950">
      {/* 50% Izquierda: Hero Visual Universitario y Telemetría Arquitectónica */}
      <div className="relative hidden w-1/2 flex-col justify-between overflow-hidden bg-gradient-to-br from-slate-900 via-brand-blue-900 to-slate-950 p-12 text-white lg:flex">
        {/* Glows de fondo */}
        <div className="absolute -left-20 -top-20 h-96 w-96 rounded-full bg-brand-blue-600/20 blur-3xl" />
        <div className="absolute -bottom-20 -right-20 h-96 w-96 rounded-full bg-brand-accent/20 blur-3xl" />

        {/* Cabecera / Identidad */}
        <div className="relative z-10 flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/10 p-2 backdrop-blur-md ring-1 ring-white/20">
            <ShieldCheck className="h-8 w-8 text-brand-accent" />
          </div>
          <div>
            <h2 className="font-display text-lg font-bold tracking-tight">UNIVERSIDAD NACIONAL</h2>
            <p className="text-xs font-semibold text-brand-accent">PORTAL DEL ESTUDIANTE v3.0</p>
          </div>
        </div>

        {/* Bloque Central Informativo */}
        <div className="relative z-10 space-y-6">
          <div className="space-y-2">
            <span className="inline-flex items-center gap-1.5 rounded-full bg-white/10 px-3 py-1 text-xs font-medium text-cyan-300 ring-1 ring-white/20">
              <Sparkles className="h-3.5 w-3.5" />
              Arquitectura Cloud-Native Zero-Trust
            </span>
            <h1 className="font-display text-3xl font-extrabold leading-tight tracking-tight text-white lg:text-4xl">
              Acceso Seguro al Campus Digital y Servicios Universitarios
            </h1>
            <p className="text-sm leading-relaxed text-slate-300">
              Integración perimetral con los 7 microservicios centrales en Go, validación asimétrica de tokens JWT RS256 vía JWKS y almacenamiento Zero-Trust en memoria volátil.
            </p>
          </div>

          {/* Tarjeta de Estado de Microservicios */}
          <div className="rounded-2xl border border-white/10 bg-white/5 p-5 backdrop-blur-md">
            <div className="mb-3 flex items-center justify-between text-xs font-semibold text-slate-300">
              <span className="flex items-center gap-2">
                <Server className="h-4 w-4 text-brand-accent" />
                MICROSERVICIOS EN LÍNEA
              </span>
              <span className="text-emerald-400">100% OPERATIVO</span>
            </div>
            <div className="grid grid-cols-2 gap-2 text-xs text-slate-300">
              <div className="flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-emerald-400" />
                <span>auth-service (:8081)</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-emerald-400" />
                <span>person-service (:8082)</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-emerald-400" />
                <span>academic & enrollment</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-emerald-400" />
                <span>finance-service (:8085)</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-emerald-400" />
                <span>library & lms (NoSQL)</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-emerald-400" />
                <span>gateway perimetral (:8080)</span>
              </div>
            </div>
          </div>
        </div>

        {/* Footer institucional */}
        <div className="relative z-10 flex items-center justify-between text-xs text-slate-400">
          <span>© 2026 Universidad Nacional - Lab 03 Azure</span>
          <span className="flex items-center gap-1">
            <Lock className="h-3.5 w-3.5 text-brand-accent" />
            Cifrado TLS 1.2+
          </span>
        </div>
      </div>

      {/* 50% Derecha: Formulario de Autenticación */}
      <div className="flex w-full flex-col justify-center px-6 py-12 lg:w-1/2 lg:px-16 xl:px-24">
        <div className="mx-auto w-full max-w-md space-y-6">
          {/* Cabecera Móvil y Título */}
          <div className="space-y-2 text-center lg:text-left">
            <div className="mb-2 inline-flex items-center gap-2 rounded-lg bg-brand-blue-50 px-3 py-1 text-xs font-semibold text-brand-blue-700 dark:bg-brand-blue-950/40 dark:text-brand-blue-400 lg:hidden">
              <ShieldCheck className="h-4 w-4" />
              Portal Estudiantil UNFPG
            </div>
            <h2 className="font-display text-2xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-3xl">
              Bienvenido al Portal
            </h2>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              Ingresa tus credenciales institucionales para acceder a tu récord académico y matrícula.
            </p>
          </div>

          {/* Tarjeta Demo Autofill */}
          <div className="flex items-center justify-between rounded-xl border border-brand-blue-200 bg-brand-blue-50/60 p-3.5 transition-colors dark:border-brand-blue-900/50 dark:bg-brand-blue-950/30">
            <div className="space-y-0.5 text-xs">
              <p className="font-semibold text-brand-blue-900 dark:text-brand-blue-200">
                Credenciales Demo de Alumno
              </p>
              <p className="text-slate-600 dark:text-slate-400">
                Usuario: <code className="font-mono font-medium text-brand-blue-700 dark:text-brand-blue-300">alu01</code> | Clave: <code className="font-mono font-medium text-brand-blue-700 dark:text-brand-blue-300">password123</code>
              </p>
            </div>
            <button
              type="button"
              onClick={handleFillDemo}
              className="flex items-center gap-1.5 rounded-lg bg-brand-blue-600 px-3 py-1.5 text-xs font-medium text-white shadow-sm transition hover:bg-brand-blue-700 active:scale-95"
            >
              <Sparkles className="h-3.5 w-3.5" />
              Autocompletar
            </button>
          </div>

          {/* Feedback Estilizado del Sobre Canónico de Error */}
          {errorDetails && (
            <div
              role="alert"
              className="space-y-2 rounded-xl border border-rose-300 bg-rose-50/80 p-4 text-xs text-rose-900 shadow-sm dark:border-rose-900/50 dark:bg-rose-950/40 dark:text-rose-200"
            >
              <div className="flex items-start gap-2.5">
                <AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-rose-600 dark:text-rose-400" />
                <div className="flex-1 space-y-1">
                  <span className="font-mono font-bold uppercase tracking-wider text-rose-700 dark:text-rose-300">
                    [{errorDetails.code}]
                  </span>
                  <p className="font-medium">{errorDetails.message}</p>
                </div>
              </div>
              <div className="flex items-center justify-between border-t border-rose-200/60 pt-2 font-mono text-[11px] text-slate-500 dark:border-rose-900/40 dark:text-slate-400">
                <span className="truncate">CorrelationId: {errorDetails.correlationId}</span>
                <button
                  type="button"
                  onClick={handleCopyCorrId}
                  className="flex items-center gap-1 rounded px-1.5 py-0.5 hover:bg-rose-200/50 dark:hover:bg-rose-900/50"
                  title="Copiar Correlation ID"
                >
                  {copiedCorrId ? (
                    <Check className="h-3 w-3 text-emerald-600" />
                  ) : (
                    <Copy className="h-3 w-3" />
                  )}
                  <span>{copiedCorrId ? 'Copiado' : 'Copiar'}</span>
                </button>
              </div>
            </div>
          )}

          {/* Formulario de Login */}
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Input Usuario */}
            <div className="space-y-1.5">
              <label
                htmlFor="username"
                className="block text-xs font-semibold uppercase tracking-wider text-slate-700 dark:text-slate-300"
              >
                Usuario Institucional
              </label>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3 text-slate-400">
                  <User className="h-4 w-4" />
                </div>
                <input
                  id="username"
                  type="text"
                  required
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="ej. alu01"
                  className="block w-full rounded-xl border border-slate-300 bg-white py-2.5 pl-10 pr-4 text-sm text-slate-900 placeholder-slate-400 transition-all focus:border-brand-blue-500 focus:outline-none focus:ring-2 focus:ring-brand-blue-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-white dark:placeholder-slate-500"
                />
              </div>
            </div>

            {/* Input Contraseña */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <label
                  htmlFor="password"
                  className="block text-xs font-semibold uppercase tracking-wider text-slate-700 dark:text-slate-300"
                >
                  Contraseña
                </label>
              </div>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3 text-slate-400">
                  <KeyRound className="h-4 w-4" />
                </div>
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="block w-full rounded-xl border border-slate-300 bg-white py-2.5 pl-10 pr-10 text-sm text-slate-900 placeholder-slate-400 transition-all focus:border-brand-blue-500 focus:outline-none focus:ring-2 focus:ring-brand-blue-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-white dark:placeholder-slate-500"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? 'Ocultar contraseña' : 'Ver contraseña'}
                  className="absolute inset-y-0 right-0 flex items-center pr-3 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            {/* Botón de Enviar */}
            <button
              type="submit"
              disabled={isLoading || !username || !password}
              className="flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-brand-blue-600 to-brand-blue-700 py-3 text-sm font-semibold text-white shadow-md transition-all hover:from-brand-blue-700 hover:to-brand-blue-800 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {isLoading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  <span>Verificando firma RS256...</span>
                </>
              ) : (
                <span>Iniciar Sesión Institucional</span>
              )}
            </button>
          </form>

          {/* Información de Seguridad Zero-Trust */}
          <div className="rounded-lg border border-slate-200 bg-slate-50 p-3 text-center text-xs text-slate-500 dark:border-slate-800 dark:bg-slate-900/50 dark:text-slate-400">
            🔒 <span className="font-medium text-slate-700 dark:text-slate-300">Sesión Zero-Trust:</span> El token de acceso se almacena exclusivamente en memoria volátil de ejecución.
          </div>
        </div>
      </div>
    </div>
  );
};
