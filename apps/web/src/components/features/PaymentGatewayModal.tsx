import React, { useState, useEffect } from 'react';
import {
  CreditCard,
  QrCode,
  Building2,
  ShieldCheck,
  CheckCircle2,
  RefreshCw,
  AlertCircle,
  Copy,
  Check,
} from 'lucide-react';
import { Modal } from '../ui/Modal';
import { usePaymentMutation } from '../../hooks/useFinance';
import { generateULID } from '../../utils/ulid';
import { formatPEN, formatDateTimePE } from '../../utils/formatters';
import type { PaymentOrder, PaymentResponse } from '../../types/api.types';

export interface PaymentGatewayModalProps {
  isOpen: boolean;
  onClose: () => void;
  order: PaymentOrder | null;
}

type PaymentTab = 'CARD' | 'YAPE' | 'PLIN' | 'TRANSFER';

export const PaymentGatewayModal: React.FC<PaymentGatewayModalProps> = ({
  isOpen,
  onClose,
  order,
}) => {
  const [activeTab, setActiveTab] = useState<PaymentTab>('CARD');
  const [lastIdempotencyKey, setLastIdempotencyKey] = useState<string>('');
  const [paymentResult, setPaymentResult] = useState<PaymentResponse | null>(null);
  const [copiedKey, setCopiedKey] = useState(false);

  // Estados de formularios simulados
  const [cardNumber, setCardNumber] = useState('4557 8900 1234 5678');
  const [cardHolder, setCardHolder] = useState('JUAN C RAMIREZ');
  const [cardExpiry, setCardExpiry] = useState('12/28');
  const [cardCvv, setCardCvv] = useState('888');
  const [otpCode, setOtpCode] = useState('123456');

  const paymentMutation = usePaymentMutation();

  // Reset al abrir un nuevo modal o cambiar de orden
  useEffect(() => {
    if (isOpen && order) {
      setLastIdempotencyKey(generateULID());
      setPaymentResult(null);
    }
  }, [isOpen, order]);

  if (!order) return null;

  const handleCopyKey = (key: string) => {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(key);
      setCopiedKey(true);
      setTimeout(() => setCopiedKey(false), 2000);
    }
  };

  // 1. Confirmar Pago con un ULID generado
  const handleConfirmPayment = () => {
    const key = generateULID();
    setLastIdempotencyKey(key);

    const methodCode = activeTab === 'CARD' ? 'CARD' : activeTab === 'TRANSFER' ? 'TRANSFER' : 'WALLET';

    paymentMutation.mutate(
      {
        orderId: order.id,
        amount: order.amount,
        methodCode,
        idempotencyKey: key,
      },
      {
        onSuccess: (data) => {
          setPaymentResult(data);
        },
      }
    );
  };

  // 2. Simular Reintento de Red con la misma Idempotency-Key
  const handleSimulateRetry = () => {
    if (!lastIdempotencyKey) return;

    const methodCode = activeTab === 'CARD' ? 'CARD' : activeTab === 'TRANSFER' ? 'TRANSFER' : 'WALLET';

    paymentMutation.mutate(
      {
        orderId: order.id,
        amount: order.amount,
        methodCode,
        idempotencyKey: lastIdempotencyKey,
      },
      {
        onSuccess: (data) => {
          setPaymentResult(data);
        },
      }
    );
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Pasarela de Pagos Institucional"
      description={`Orden de Pago #${order.id} · ${order.conceptName || 'Matrícula Universitaria'}`}
      maxWidth="lg"
    >
      <div className="space-y-5">
        {/* Resumen del Monto a Pagar */}
        <div className="flex items-center justify-between rounded-xl bg-slate-50 p-4 border border-slate-200/80 dark:bg-slate-800/40 dark:border-slate-800">
          <div>
            <span className="text-xs text-slate-500 dark:text-slate-400">Total a Cancelar</span>
            <p className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              {formatPEN(order.amount)}
            </p>
          </div>
          <div className="text-right">
            <span className="inline-flex items-center gap-1.5 rounded-full bg-brand-blue-500/10 px-3 py-1 text-xs font-semibold text-brand-blue-600 dark:text-brand-blue-400">
              <ShieldCheck className="h-4 w-4" /> Idempotencia Redis 7
            </span>
            <p className="mt-1 font-mono text-[11px] text-slate-400">
              Key: {lastIdempotencyKey ? `${lastIdempotencyKey.slice(0, 10)}...` : 'Pendiente'}
            </p>
          </div>
        </div>

        {/* Banner de Resultado de Pago Exitoso */}
        {paymentResult && (
          <div className="rounded-xl border border-emerald-500/30 bg-emerald-500/10 p-4 text-emerald-800 dark:text-emerald-300 animate-in fade-in zoom-in-95">
            <div className="flex items-start gap-3">
              <CheckCircle2 className="h-6 w-6 text-emerald-500 flex-shrink-0 mt-0.5" />
              <div className="flex-1 space-y-1 text-xs">
                <div className="flex items-center justify-between">
                  <span className="font-bold text-sm text-emerald-900 dark:text-emerald-200">
                    ¡Transacción Procesada Exitosamente!
                  </span>
                  <span className="font-mono text-[10px] bg-emerald-600/20 text-emerald-700 dark:text-emerald-300 px-2 py-0.5 rounded">
                    HTTP 200 OK
                  </span>
                </div>
                <p>
                  Referencia de Pago:{' '}
                  <span className="font-mono font-bold text-emerald-900 dark:text-emerald-100">
                    {paymentResult.transactionRef}
                  </span>
                </p>
                <div className="flex items-center gap-1.5 pt-1">
                  <span className="text-slate-500 dark:text-slate-400">Idempotency-Key:</span>
                  <span className="font-mono text-[11px] font-semibold">
                    {paymentResult.idempotencyKey}
                  </span>
                  <button
                    type="button"
                    onClick={() => handleCopyKey(paymentResult.idempotencyKey)}
                    className="p-1 hover:bg-emerald-500/20 rounded transition-colors text-emerald-700 dark:text-emerald-300"
                    title="Copiar llave"
                  >
                    {copiedKey ? <Check className="h-3 w-3" /> : <Copy className="h-3 w-3" />}
                  </button>
                </div>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 pt-0.5">
                  Fecha de liquidación: {formatDateTimePE(paymentResult.paidAt)}
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Mensaje de error de mutación */}
        {paymentMutation.isError && (
          <div className="rounded-xl border border-rose-500/30 bg-rose-500/10 p-4 text-rose-700 dark:text-rose-400 text-xs flex items-center gap-2">
            <AlertCircle className="h-5 w-5 flex-shrink-0" />
            <span>{paymentMutation.error.message || 'Error al procesar el pago. Intente nuevamente.'}</span>
          </div>
        )}

        {/* Pestañas de Métodos de Pago */}
        <div className="border-b border-slate-200 dark:border-slate-800">
          <nav className="flex space-x-2">
            <button
              type="button"
              onClick={() => setActiveTab('CARD')}
              className={`flex items-center gap-2 border-b-2 px-3 py-2 text-xs font-semibold transition-colors ${
                activeTab === 'CARD'
                  ? 'border-brand-blue-500 text-brand-blue-600 dark:text-brand-blue-400'
                  : 'border-transparent text-slate-500 hover:text-slate-700 dark:text-slate-400'
              }`}
            >
              <CreditCard className="h-4 w-4" /> Tarjeta Crédito / Débito
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('YAPE')}
              className={`flex items-center gap-2 border-b-2 px-3 py-2 text-xs font-semibold transition-colors ${
                activeTab === 'YAPE'
                  ? 'border-purple-600 text-purple-600 dark:text-purple-400'
                  : 'border-transparent text-slate-500 hover:text-slate-700 dark:text-slate-400'
              }`}
            >
              <QrCode className="h-4 w-4" /> Yape
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('PLIN')}
              className={`flex items-center gap-2 border-b-2 px-3 py-2 text-xs font-semibold transition-colors ${
                activeTab === 'PLIN'
                  ? 'border-cyan-600 text-cyan-600 dark:text-cyan-400'
                  : 'border-transparent text-slate-500 hover:text-slate-700 dark:text-slate-400'
              }`}
            >
              <QrCode className="h-4 w-4" /> Plin
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('TRANSFER')}
              className={`flex items-center gap-2 border-b-2 px-3 py-2 text-xs font-semibold transition-colors ${
                activeTab === 'TRANSFER'
                  ? 'border-amber-600 text-amber-600 dark:text-amber-400'
                  : 'border-transparent text-slate-500 hover:text-slate-700 dark:text-slate-400'
              }`}
            >
              <Building2 className="h-4 w-4" /> Transferencia Bancaria
            </button>
          </nav>
        </div>

        {/* Contenido según pestaña */}
        {activeTab === 'CARD' && (
          <div className="space-y-3">
            <div>
              <label className="block text-[11px] font-semibold text-slate-700 dark:text-slate-300">
                Número de Tarjeta
              </label>
              <input
                type="text"
                value={cardNumber}
                onChange={(e) => setCardNumber(e.target.value)}
                placeholder="4557 0000 0000 0000"
                className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 font-mono text-xs text-slate-900 shadow-sm focus:border-brand-blue-500 focus:outline-none dark:border-slate-700 dark:bg-slate-800 dark:text-white"
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-[11px] font-semibold text-slate-700 dark:text-slate-300">
                  Fecha Vencimiento (MM/AA)
                </label>
                <input
                  type="text"
                  value={cardExpiry}
                  onChange={(e) => setCardExpiry(e.target.value)}
                  placeholder="12/28"
                  className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 font-mono text-xs text-slate-900 shadow-sm focus:border-brand-blue-500 focus:outline-none dark:border-slate-700 dark:bg-slate-800 dark:text-white"
                />
              </div>
              <div>
                <label className="block text-[11px] font-semibold text-slate-700 dark:text-slate-300">
                  CVV / CVC
                </label>
                <input
                  type="password"
                  value={cardCvv}
                  onChange={(e) => setCardCvv(e.target.value)}
                  placeholder="888"
                  maxLength={4}
                  className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 font-mono text-xs text-slate-900 shadow-sm focus:border-brand-blue-500 focus:outline-none dark:border-slate-700 dark:bg-slate-800 dark:text-white"
                />
              </div>
            </div>
            <div>
              <label className="block text-[11px] font-semibold text-slate-700 dark:text-slate-300">
                Titular de la Tarjeta
              </label>
              <input
                type="text"
                value={cardHolder}
                onChange={(e) => setCardHolder(e.target.value)}
                placeholder="JUAN C RAMIREZ"
                className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs text-slate-900 shadow-sm focus:border-brand-blue-500 focus:outline-none dark:border-slate-700 dark:bg-slate-800 dark:text-white uppercase"
              />
            </div>
          </div>
        )}

        {(activeTab === 'YAPE' || activeTab === 'PLIN') && (
          <div className="flex flex-col items-center justify-center p-4 rounded-xl border border-dashed border-slate-300 dark:border-slate-700 bg-slate-50/50 dark:bg-slate-800/30 text-center space-y-3">
            <div className={`p-4 rounded-2xl ${activeTab === 'YAPE' ? 'bg-purple-600 text-white' : 'bg-cyan-600 text-white'} shadow-md`}>
              <QrCode className="h-28 w-28" />
            </div>
            <div className="space-y-1">
              <span className="text-xs font-bold text-slate-800 dark:text-slate-200">
                Escanea el código QR desde tu app {activeTab === 'YAPE' ? 'Yape' : 'Plin'}
              </span>
              <p className="text-[11px] text-slate-500">
                O transfiere al número: <span className="font-mono font-bold text-slate-900 dark:text-white">987-654-321</span> (UNFPG Tesorería)
              </p>
            </div>
            <div className="w-full max-w-xs text-left">
              <label className="block text-[11px] font-semibold text-slate-700 dark:text-slate-300">
                Código de Aprobación de 6 dígitos
              </label>
              <input
                type="text"
                value={otpCode}
                onChange={(e) => setOtpCode(e.target.value)}
                maxLength={6}
                placeholder="123456"
                className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-center font-mono text-sm tracking-widest text-slate-900 focus:border-purple-500 focus:outline-none dark:border-slate-700 dark:bg-slate-800 dark:text-white"
              />
            </div>
          </div>
        )}

        {activeTab === 'TRANSFER' && (
          <div className="space-y-3 rounded-xl border border-slate-200 bg-slate-50/50 p-4 text-xs dark:border-slate-800 dark:bg-slate-800/30">
            <p className="font-semibold text-slate-700 dark:text-slate-300">
              Cuentas Recaudadoras Oficiales de la Universidad:
            </p>
            <div className="space-y-2 font-mono text-[11px]">
              <div className="rounded border border-slate-200 bg-white p-2.5 dark:border-slate-700 dark:bg-slate-900">
                <span className="block font-sans text-xs font-bold text-brand-blue-600 dark:text-brand-blue-400">
                  Banco de Crédito del Perú (BCP)
                </span>
                <span>Cta Cte: 191-98765432-0-99 · CCI: 002-191-009876543209-54</span>
              </div>
              <div className="rounded border border-slate-200 bg-white p-2.5 dark:border-slate-700 dark:bg-slate-900">
                <span className="block font-sans text-xs font-bold text-brand-blue-600 dark:text-brand-blue-400">
                  BBVA Perú
                </span>
                <span>Cta Cte: 0011-0123-0100098765 · CCI: 011-123-000100098765-12</span>
              </div>
            </div>
          </div>
        )}

        {/* Botones de Acción */}
        <div className="flex flex-col sm:flex-row items-center gap-3 pt-2">
          {/* Botón 1: Confirmar Pago con nuevo ULID */}
          <button
            type="button"
            onClick={handleConfirmPayment}
            disabled={paymentMutation.isPending}
            className="flex-1 w-full flex items-center justify-center gap-2 rounded-xl bg-brand-blue-600 px-4 py-2.5 text-xs font-bold text-white shadow-md hover:bg-brand-blue-700 active:scale-98 disabled:opacity-50 transition-all"
          >
            {paymentMutation.isPending ? (
              <>
                <RefreshCw className="h-4 w-4 animate-spin" />
                <span>Procesando Pago...</span>
              </>
            ) : (
              <>
                <ShieldCheck className="h-4 w-4" />
                <span>Confirmar Pago ({formatPEN(order.amount)})</span>
              </>
            )}
          </button>

          {/* Botón 2: Simular Reintento de Red (Misma Idempotency-Key) */}
          <button
            type="button"
            onClick={handleSimulateRetry}
            disabled={paymentMutation.isPending || !lastIdempotencyKey}
            className="w-full sm:w-auto flex items-center justify-center gap-2 rounded-xl border border-amber-500/40 bg-amber-500/10 px-4 py-2.5 text-xs font-bold text-amber-700 hover:bg-amber-500/20 active:scale-98 disabled:opacity-40 dark:text-amber-300 transition-all"
            title="Envía exactamente la misma cabecera Idempotency-Key para demostrar que Redis devuelve el mismo registro sin duplicar cobro"
          >
            <RefreshCw className={`h-4 w-4 ${paymentMutation.isPending ? 'animate-spin' : ''}`} />
            <span>Reintentar Red (Misma Key)</span>
          </button>
        </div>
      </div>
    </Modal>
  );
};
