import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { financeService } from '../api/services/finance.service';
import type { PaymentOrder, PaymentResponse } from '../types/api.types';

import { useAuthStore } from '../store/auth.store';

export interface ProcessPaymentParams {
  orderId: number;
  amount: number;
  methodCode: string;
  idempotencyKey: string;
}

export function useOrdersQuery() {
  const userId = useAuthStore((state) => state.user?.userId);

  return useQuery<PaymentOrder[], Error>({
    queryKey: ['finance', 'orders', userId ?? 'anonymous'],
    queryFn: financeService.getMyOrders,
    enabled: Boolean(userId),
  });
}

export function usePaymentMutation() {
  const queryClient = useQueryClient();
  const userId = useAuthStore((state) => state.user?.userId);

  return useMutation<PaymentResponse, Error, ProcessPaymentParams>({
    mutationFn: ({ orderId, amount, methodCode, idempotencyKey }: ProcessPaymentParams) =>
      financeService.processPayment(orderId, amount, methodCode, idempotencyKey),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['finance', 'orders', userId ?? 'anonymous'] });
    },
  });
}
