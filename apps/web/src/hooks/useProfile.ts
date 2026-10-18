import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { personService } from '../api/services/person.service';
import { useAuthStore } from '../store/auth.store';
import type { UserProfile, UpdateContactRequest } from '../types/api.types';

export function useProfileQuery() {
  const userId = useAuthStore((state) => state.user?.userId);

  return useQuery<UserProfile, Error>({
    queryKey: ['person', 'profile', userId ?? 'anonymous'],
    queryFn: personService.getProfile,
    enabled: Boolean(userId),
  });
}

export function useUpdateContactMutation() {
  const queryClient = useQueryClient();
  const userId = useAuthStore((state) => state.user?.userId);

  return useMutation<{ message: string }, Error, UpdateContactRequest>({
    mutationFn: (data: UpdateContactRequest) => personService.updateContact(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['person', 'profile', userId ?? 'anonymous'] });
    },
  });
}
