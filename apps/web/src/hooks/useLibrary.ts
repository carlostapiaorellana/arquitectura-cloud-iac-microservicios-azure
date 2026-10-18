import { useQuery } from '@tanstack/react-query';
import { libraryService } from '../api/services/library.service';
import type { Book, Loan } from '../types/api.types';

export function useBooksQuery(category?: string) {
  return useQuery<Book[], Error>({
    queryKey: ['library', 'books', category ?? 'ALL'],
    queryFn: () => libraryService.getBooks(category),
  });
}

import { useAuthStore } from '../store/auth.store';

export function useMyLoansQuery() {
  const userId = useAuthStore((state) => state.user?.userId);

  return useQuery<Loan[], Error>({
    queryKey: ['library', 'my-loans', userId ?? 'anonymous'],
    queryFn: libraryService.getMyLoans,
    enabled: Boolean(userId),
  });
}
