import { QueryClient } from '@tanstack/react-query';

// Instancia centralizada y exportada de TanStack Query
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: (failureCount, error: unknown) => {
        const status = (error as { response?: { status?: number } })?.response?.status;
        if (status === 401 || status === 403 || status === 404) {
          return false;
        }
        return failureCount < 2;
      },
      staleTime: 1000 * 10, // 10 segundos de frescura
      gcTime: 1000 * 60,    // 1 minuto de recolección de basura
    },
  },
});
