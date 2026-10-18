import React, { useState } from 'react';
import {
  CreditCard,
  Clock,
  ShieldCheck,
  CheckCircle2,
  DollarSign,
  AlertCircle,
  RefreshCw,
  Calendar,
} from 'lucide-react';
import { useOrdersQuery } from '../hooks/useFinance';
import { PaymentGatewayModal } from '../components/features/PaymentGatewayModal';
import { TableRowSkeleton, Skeleton } from '../components/ui/Skeleton';
import { formatPEN, formatDatePE } from '../utils/formatters';
import type { PaymentOrder } from '../types/api.types';

export const FinancePaymentsPage: React.FC = () => {
  const [selectedOrder, setSelectedOrder] = useState<PaymentOrder | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const ordersQuery = useOrdersQuery();

  const handleOpenPayment = (order: PaymentOrder) => {
    setSelectedOrder(order);
    setIsModalOpen(true);
  };

  const isLoading = ordersQuery.isLoading;
  const isError = ordersQuery.isError;
  const orders = ordersQuery.data || [];

  // Cálculos de resumen financiero
  const pendingOrders = orders.filter(
    (o) =>
      o.statusCode === 'PENDING' ||
      o.statusId === 1 ||
      (o.statusName && o.statusName.toUpperCase().includes('PEND'))
  );

  const paidOrders = orders.filter(
    (o) =>
      o.statusCode === 'PAID' ||
      o.statusId === 2 ||
      (o.statusName && o.statusName.toUpperCase().includes('PAG'))
  );

  const pendingAmount = pendingOrders.reduce((sum, o) => sum + (o.amount || 0), 0);
  const paidAmount = paidOrders.reduce((sum, o) => sum + (o.amount || 0), 0);
  const totalInvoiced = orders.reduce((sum, o) => sum + (o.amount || 0), 0);

  return (
    <div className="space-y-6">
      {/* Encabezado */}
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <h2 className="font-display text-xl font-bold text-slate-900 dark:text-white">
            Tesorería & Pagos en Línea
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Órdenes de matrícula y conceptos académicos protegidos por pasarela idempotente con Redis 7.
          </p>
        </div>
        <button
          type="button"
          onClick={() => ordersQuery.refetch()}
          className="inline-flex items-center gap-1.5 self-start rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 shadow-sm hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-900 dark:text-slate-300"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${isLoading ? 'animate-spin' : ''}`} />
          <span>Actualizar Órdenes</span>
        </button>
      </div>

      {/* Resumen Financiero en 3 Tarjetas */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {/* Deuda Pendiente */}
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400">
              Deuda Pendiente
            </span>
            <div className="rounded-lg bg-amber-500/10 p-2 text-amber-600 dark:text-amber-400">
              <Clock className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3">
            {isLoading ? (
              <Skeleton className="h-8 w-28" />
            ) : (
              <span className="font-display text-2xl font-bold text-amber-600 dark:text-amber-400">
                {formatPEN(pendingAmount)}
              </span>
            )}
          </div>
          <span className="mt-1 inline-block text-[11px] font-semibold text-slate-500">
            {pendingOrders.length} orden(es) pendiente(s)
          </span>
        </div>

        {/* Órdenes Pagadas */}
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400">
              Monto Pagado
            </span>
            <div className="rounded-lg bg-emerald-500/10 p-2 text-emerald-600 dark:text-emerald-400">
              <CheckCircle2 className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3">
            {isLoading ? (
              <Skeleton className="h-8 w-28" />
            ) : (
              <span className="font-display text-2xl font-bold text-emerald-600 dark:text-emerald-400">
                {formatPEN(paidAmount)}
              </span>
            )}
          </div>
          <span className="mt-1 inline-block text-[11px] font-semibold text-slate-500">
            {paidOrders.length} orden(es) cancelada(s)
          </span>
        </div>

        {/* Total Facturado */}
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400">
              Total Facturado
            </span>
            <div className="rounded-lg bg-brand-blue-500/10 p-2 text-brand-blue-600 dark:text-brand-blue-400">
              <DollarSign className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3">
            {isLoading ? (
              <Skeleton className="h-8 w-28" />
            ) : (
              <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
                {formatPEN(totalInvoiced)}
              </span>
            )}
          </div>
          <span className="mt-1 inline-block text-[11px] font-semibold text-slate-500">
            {orders.length} comprobante(s) emitido(s)
          </span>
        </div>
      </div>

      {/* Error */}
      {isError && (
        <div className="flex items-center gap-3 rounded-xl border border-rose-500/20 bg-rose-500/10 p-4 text-xs text-rose-700 dark:text-rose-400">
          <AlertCircle className="h-5 w-5 flex-shrink-0" />
          <span>Error al consultar las órdenes de pago en finance-service.</span>
        </div>
      )}

      {/* Tabla de Órdenes de Pago */}
      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
        <div className="flex items-center justify-between border-b border-slate-200 pb-4 dark:border-slate-800">
          <div className="flex items-center gap-3">
            <div className="rounded-xl bg-amber-500/10 p-2.5 text-amber-600 dark:text-amber-400">
              <CreditCard className="h-5 w-5" />
            </div>
            <div>
              <h3 className="font-display text-sm font-bold text-slate-900 dark:text-white">
                Historial de Órdenes y Conceptos de Pago
              </h3>
              <p className="text-xs text-slate-500">
                Transacciones protegidas con clave ULID para prevenir débitos duplicados.
              </p>
            </div>
          </div>
          <div className="hidden sm:flex items-center gap-1.5 text-xs text-slate-500">
            <ShieldCheck className="h-4 w-4 text-emerald-500" />
            <span>Redis Idempotent Pipeline</span>
          </div>
        </div>

        <div className="mt-6 overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="border-b border-slate-200 text-slate-500 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/30">
              <tr>
                <th className="py-3 px-3 font-semibold uppercase tracking-wider">Orden #</th>
                <th className="py-3 px-3 font-semibold uppercase tracking-wider">Concepto</th>
                <th className="py-3 px-3 font-semibold uppercase tracking-wider">Monto (PEN)</th>
                <th className="py-3 px-3 font-semibold uppercase tracking-wider">Vencimiento</th>
                <th className="py-3 px-3 font-semibold uppercase tracking-wider">Estado</th>
                <th className="py-3 px-3 text-right font-semibold uppercase tracking-wider">Acción</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700 dark:divide-slate-800 dark:text-slate-300">
              {isLoading && orders.length === 0 && (
                <>
                  <TableRowSkeleton columns={6} />
                  <TableRowSkeleton columns={6} />
                </>
              )}

              {!isLoading && orders.length === 0 && (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-500">
                    No se encontraron órdenes de pago para el estudiante autenticado.
                  </td>
                </tr>
              )}

              {orders.map((order) => {
                const isPaid =
                  order.statusCode === 'PAID' ||
                  order.statusId === 2 ||
                  (order.statusName && order.statusName.toUpperCase().includes('PAG'));

                return (
                  <tr
                    key={order.id}
                    className="hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors"
                  >
                    <td className="py-3.5 px-3 font-mono font-bold text-slate-900 dark:text-white">
                      #{order.id}
                    </td>
                    <td className="py-3.5 px-3">
                      <span className="font-semibold text-slate-900 dark:text-white block">
                        {order.conceptName || 'Matrícula Ordinaria 2026-I'}
                      </span>
                      <span className="font-mono text-[10px] text-slate-400">
                        {order.conceptCode || 'MAT-ORD-2026'}
                      </span>
                    </td>
                    <td className="py-3.5 px-3 font-display font-bold text-sm text-slate-900 dark:text-white">
                      {formatPEN(order.amount)}
                    </td>
                    <td className="py-3.5 px-3 text-slate-500 dark:text-slate-400">
                      <span className="inline-flex items-center gap-1">
                        <Calendar className="h-3.5 w-3.5 text-slate-400" />
                        {formatDatePE(order.dueDate || order.createdAt)}
                      </span>
                    </td>
                    <td className="py-3.5 px-3">
                      {isPaid ? (
                        <span className="inline-flex items-center gap-1 rounded-full bg-emerald-500/10 px-2.5 py-0.5 text-xs font-semibold text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
                          <CheckCircle2 className="h-3.5 w-3.5" /> PAGADO
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 rounded-full bg-amber-500/10 px-2.5 py-0.5 text-xs font-semibold text-amber-600 dark:text-amber-400 border border-amber-500/20">
                          <Clock className="h-3.5 w-3.5" /> PENDIENTE
                        </span>
                      )}
                    </td>
                    <td className="py-3.5 px-3 text-right">
                      {isPaid ? (
                        <span className="text-[11px] font-medium text-slate-400">
                          Conciliado
                        </span>
                      ) : (
                        <button
                          type="button"
                          onClick={() => handleOpenPayment(order)}
                          className="rounded-lg bg-brand-blue-600 px-3.5 py-1.5 text-xs font-semibold text-white shadow-sm hover:bg-brand-blue-700 active:scale-95 transition-all"
                        >
                          Pagar Ahora
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal de Pasarela de Pago */}
      <PaymentGatewayModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        order={selectedOrder}
      />
    </div>
  );
};
