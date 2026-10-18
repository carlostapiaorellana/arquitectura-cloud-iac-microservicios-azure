import { useQuery } from '@tanstack/react-query';
import { libraryService } from '../api/services/library.service';
import type { Book, Loan } from '../types/api.types';

export function useBooksQuery(category?: string) {
  return useQuery<Book[], Error>({
    queryKey: ['library', 'books', category ?? 'ALL'],
    queryFn: () => libraryService.getBooks(category),
  });
}

export function useMyLoansQuery() {
  return useQuery<Loan[], Error>({
    queryKey: ['library', 'my-loans'],
    queryFn: libraryService.getMyLoans,
  });
}
