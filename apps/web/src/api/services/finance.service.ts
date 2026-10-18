import { apiClient } from '../client';
import type { PaymentOrder, PaymentResponse, ProcessPaymentRequest } from '../../types/api.types';

export const financeService = {
  /**
   * Obtiene el listado de órdenes de pago del estudiante
   */
  getMyOrders: async (): Promise<PaymentOrder[]> => {
    const response = await apiClient.get<PaymentOrder[]>('/finance/my-orders');
    return response.data;
  },

  /**
   * Procesa una transacción de pago con control estricto de idempotencia (Redis 7)
   */
  processPayment: async (
    orderId: number,
    amount: number,
    methodCode: string,
    idempotencyKey: string
  ): Promise<PaymentResponse> => {
    const payload: ProcessPaymentRequest = {
      paymentOrderId: orderId,
      methodCode,
      amount,
    };

    const response = await apiClient.post<PaymentResponse>('/finance/payments', payload, {
      headers: {
        'Idempotency-Key': idempotencyKey,
      },
    });

    return response.data;
  },
};
