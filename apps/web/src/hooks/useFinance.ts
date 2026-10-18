import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { financeService } from '../api/services/finance.service';
import type { PaymentOrder, PaymentResponse } from '../types/api.types';

export interface ProcessPaymentParams {
  orderId: number;
  amount: number;
  methodCode: string;
  idempotencyKey: string;
}

export function useOrdersQuery() {
  return useQuery<PaymentOrder[], Error>({
    queryKey: ['finance', 'orders'],
    queryFn: financeService.getMyOrders,
  });
}

export function usePaymentMutation() {
  const queryClient = useQueryClient();

  return useMutation<PaymentResponse, Error, ProcessPaymentParams>({
    mutationFn: ({ orderId, amount, methodCode, idempotencyKey }: ProcessPaymentParams) =>
      financeService.processPayment(orderId, amount, methodCode, idempotencyKey),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['finance', 'orders'] });
    },
  });
}
