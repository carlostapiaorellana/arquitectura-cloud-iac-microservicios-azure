import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { personService } from '../api/services/person.service';
import type { UserProfile, UpdateContactRequest } from '../types/api.types';

export function useProfileQuery() {
  return useQuery<UserProfile, Error>({
    queryKey: ['person', 'profile'],
    queryFn: personService.getProfile,
  });
}

export function useUpdateContactMutation() {
  const queryClient = useQueryClient();

  return useMutation<{ message: string }, Error, UpdateContactRequest>({
    mutationFn: (data: UpdateContactRequest) => personService.updateContact(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['person', 'profile'] });
    },
  });
}
