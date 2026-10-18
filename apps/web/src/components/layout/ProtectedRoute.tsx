import React, { useEffect, useState } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuthStore } from '../../store/auth.store';
import { authService } from '../../api/services/auth.service';
import { Loader2 } from 'lucide-react';

interface ProtectedRouteProps {
  children: React.ReactElement;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
  const location = useLocation();
  const { accessToken, refreshToken, setAccessToken, clearSession } = useAuthStore();
  const [isHydrating, setIsHydrating] = useState<boolean>(!accessToken && !!refreshToken);

  useEffect(() => {
    let isMounted = true;

    async function restoreSession() {
      if (!accessToken && refreshToken) {
        try {
          const res = await authService.refreshToken(refreshToken);
          if (isMounted) {
            setAccessToken(res.accessToken);
          }
        } catch {
          if (isMounted) {
            clearSession();
          }
        } finally {
          if (isMounted) {
            setIsHydrating(false);
          }
        }
      } else {
        setIsHydrating(false);
      }
    }

    if (!accessToken && refreshToken) {
      restoreSession();
    } else {
      setIsHydrating(false);
    }

    return () => {
      isMounted = false;
    };
  }, [accessToken, refreshToken, setAccessToken, clearSession]);

  if (isHydrating) {
    return (
      <div className="flex h-screen w-full items-center justify-center bg-slate-50 dark:bg-slate-950">
        <div className="flex flex-col items-center gap-3 text-slate-600 dark:text-slate-400">
          <Loader2 className="h-8 w-8 animate-spin text-brand-blue-500" />
          <p className="text-sm font-medium">Restaurando sesión institucional...</p>
        </div>
      </div>
    );
  }

  // Si no hay token de acceso ni token de refresco, redirigir a login preservando origen
  if (!accessToken && !refreshToken) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  return children;
};
