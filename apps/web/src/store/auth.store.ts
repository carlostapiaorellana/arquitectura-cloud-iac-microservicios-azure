import { create } from 'zustand';
import type { AuthLoginResponse } from '../types/api.types';
import { queryClient } from '../api/queryClient';

export interface AuthUserMeta {
  userId: string;
  role: string;
  roles: string[];
  username: string;
  tokenType: string;
}

interface StoredAuthMeta {
  refreshToken?: string;
  user: AuthUserMeta;
}

const STORAGE_KEY = 'unfpg_auth_meta';
const BROADCAST_CHANNEL_NAME = 'unfpg_auth_channel';

// Instancia de BroadcastChannel para sincronización multi-pestaña
let authBroadcast: BroadcastChannel | null = null;
if (typeof window !== 'undefined' && 'BroadcastChannel' in window) {
  authBroadcast = new BroadcastChannel(BROADCAST_CHANNEL_NAME);
}

// Cargar metadatos previos desde localStorage
function loadInitialMeta(): { refreshToken: string | null; user: AuthUserMeta | null } {
  if (typeof window === 'undefined') return { refreshToken: null, user: null };
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { refreshToken: null, user: null };
    const parsed: StoredAuthMeta = JSON.parse(raw);
    return {
      refreshToken: parsed.refreshToken || null,
      user: parsed.user || null,
    };
  } catch (err) {
    console.error('Error al parsear auth meta de localStorage:', err);
    return { refreshToken: null, user: null };
  }
}

interface AuthState {
  // accessToken reside ÚNICAMENTE en memoria RAM para neutralizar vectores XSS
  accessToken: string | null;
  refreshToken: string | null;
  user: AuthUserMeta | null;
  isAuthenticated: boolean;

  setSession: (data: AuthLoginResponse) => void;
  setAccessToken: (token: string, newRefreshToken?: string) => void;
  clearSession: (broadcast?: boolean) => void;
}

const initialMeta = loadInitialMeta();

export const useAuthStore = create<AuthState>((set) => ({
  accessToken: null, // Solo en memoria
  refreshToken: initialMeta.refreshToken,
  user: initialMeta.user,
  isAuthenticated: false, // Se considerará plenamente autenticado cuando tenga accessToken en memoria

  setSession: (data: AuthLoginResponse) => {
    // Purgar cualquier caché residual en memoria de sesiones previas
    queryClient.clear();

    const userMeta: AuthUserMeta = {
      userId: data.userId,
      role: data.role,
      roles: data.roles || [data.role],
      username: data.username,
      tokenType: data.tokenType || 'Bearer',
    };

    // Guardar refreshToken y metadatos públicos en localStorage
    if (typeof window !== 'undefined') {
      const metaToStore: StoredAuthMeta = {
        refreshToken: data.refreshToken,
        user: userMeta,
      };
      localStorage.setItem(STORAGE_KEY, JSON.stringify(metaToStore));
    }

    set({
      accessToken: data.accessToken,
      refreshToken: data.refreshToken || null,
      user: userMeta,
      isAuthenticated: true,
    });
  },

  setAccessToken: (token: string, newRefreshToken?: string) => {
    if (newRefreshToken && typeof window !== 'undefined') {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        try {
          const parsed: StoredAuthMeta = JSON.parse(raw);
          parsed.refreshToken = newRefreshToken;
          localStorage.setItem(STORAGE_KEY, JSON.stringify(parsed));
        } catch {
          // ignore
        }
      }
    }
    set((state) => ({
      accessToken: token,
      refreshToken: newRefreshToken ?? state.refreshToken,
      isAuthenticated: true,
    }));
  },

  clearSession: (broadcast = true) => {
    // Purgar inmediatamente la caché de queries en memoria
    queryClient.clear();

    if (typeof window !== 'undefined') {
      localStorage.removeItem(STORAGE_KEY);
      if (broadcast && authBroadcast) {
        authBroadcast.postMessage({ type: 'LOGOUT' });
      }
    }

    set({
      accessToken: null,
      refreshToken: null,
      user: null,
      isAuthenticated: false,
    });
  },
}));

// Listener de sincronización multi-pestaña
if (authBroadcast) {
  authBroadcast.onmessage = (event) => {
    if (event.data?.type === 'LOGOUT') {
      // Limpiar memoria interna sin retransmitir
      useAuthStore.getState().clearSession(false);
      if (typeof window !== 'undefined' && window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
  };
}
