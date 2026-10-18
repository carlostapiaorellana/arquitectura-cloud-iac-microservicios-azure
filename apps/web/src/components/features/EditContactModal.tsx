import React, { useState, useEffect } from 'react';
import { RefreshCw, CheckCircle2, AlertCircle, Save } from 'lucide-react';
import { Modal } from '../ui/Modal';
import { useUpdateContactMutation } from '../../hooks/useProfile';
import type { UserProfile } from '../../types/api.types';

export interface EditContactModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialData?: UserProfile | null;
}

export const EditContactModal: React.FC<EditContactModalProps> = ({
  isOpen,
  onClose,
  initialData,
}) => {
  const [address, setAddress] = useState('');
  const [phone, setPhone] = useState('');
  const [mobile, setMobile] = useState('');
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const updateMutation = useUpdateContactMutation();

  useEffect(() => {
    if (initialData) {
      setAddress(initialData.address || '');
      setPhone(initialData.phone || '');
      setMobile(initialData.mobile || '');
      setSuccessMsg(null);
    }
  }, [initialData, isOpen]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSuccessMsg(null);

    updateMutation.mutate(
      {
        address: address.trim(),
        phone: phone.trim() || undefined,
        mobile: mobile.trim() || undefined,
      },
      {
        onSuccess: (data) => {
          setSuccessMsg(data.message || 'Datos de contacto actualizados correctamente.');
          setTimeout(() => {
            onClose();
          }, 1500);
        },
      }
    );
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Actualizar Datos de Contacto"
      description="Modifique su dirección y números telefónicos registrados en el padrón institucional."
      maxWidth="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        {successMsg && (
          <div className="flex items-center gap-2 rounded-xl border border-emerald-500/30 bg-emerald-500/10 p-3 text-xs text-emerald-800 dark:text-emerald-300">
            <CheckCircle2 className="h-5 w-5 flex-shrink-0 text-emerald-500" />
            <span>{successMsg}</span>
          </div>
        )}

        {updateMutation.isError && (
          <div className="flex items-center gap-2 rounded-xl border border-rose-500/30 bg-rose-500/10 p-3 text-xs text-rose-700 dark:text-rose-400">
            <AlertCircle className="h-5 w-5 flex-shrink-0" />
            <span>{updateMutation.error.message || 'Error al actualizar datos.'}</span>
          </div>
        )}

        <div>
          <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300">
            Dirección Domiciliaria <span className="text-rose-500">*</span>
          </label>
          <input
            type="text"
            required
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            placeholder="Ej. Av. Universitaria 1234, Lima"
            className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs text-slate-900 shadow-sm focus:border-brand-blue-500 focus:outline-none dark:border-slate-700 dark:bg-slate-800 dark:text-white"
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300">
              Teléfono Celular (Móvil)
            </label>
            <input
              type="tel"
              value={mobile}
              onChange={(e) => setMobile(e.target.value)}
              placeholder="Ej. 987654321"
              className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 font-mono text-xs text-slate-900 shadow-sm focus:border-brand-blue-500 focus:outline-none dark:border-slate-700 dark:bg-slate-800 dark:text-white"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300">
              Teléfono Fijo
            </label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="Ej. 014567890"
              className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 font-mono text-xs text-slate-900 shadow-sm focus:border-brand-blue-500 focus:outline-none dark:border-slate-700 dark:bg-slate-800 dark:text-white"
            />
          </div>
        </div>

        <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100 dark:border-slate-800">
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg border border-slate-200 px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
          >
            Cancelar
          </button>
          <button
            type="submit"
            disabled={updateMutation.isPending}
            className="flex items-center gap-1.5 rounded-lg bg-brand-blue-600 px-4 py-2 text-xs font-semibold text-white shadow-sm hover:bg-brand-blue-700 active:scale-95 disabled:opacity-50"
          >
            {updateMutation.isPending ? (
              <>
                <RefreshCw className="h-4 w-4 animate-spin" />
                <span>Guardando...</span>
              </>
            ) : (
              <>
                <Save className="h-4 w-4" />
                <span>Guardar Cambios</span>
              </>
            )}
          </button>
        </div>
      </form>
    </Modal>
  );
};
