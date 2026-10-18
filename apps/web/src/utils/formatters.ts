// ============================================================================
// Formateadores estándar para la plataforma universitaria UNFPG
// ============================================================================

/**
 * Formatea un valor numérico a moneda Soles Peruanos (PEN / S/)
 */
export function formatPEN(amount: number): string {
  if (isNaN(amount) || amount === null || amount === undefined) {
    return 'S/ 0.00';
  }
  return new Intl.NumberFormat('es-PE', {
    style: 'currency',
    currency: 'PEN',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

/**
 * Formatea una fecha ISO (o YYYY-MM-DD) al estándar peruano dd/mm/yyyy
 */
export function formatDatePE(dateInput: string | Date | undefined | null): string {
  if (!dateInput) return '-';
  try {
    const date = typeof dateInput === 'string' ? new Date(dateInput) : dateInput;
    if (isNaN(date.getTime())) return String(dateInput);
    return new Intl.DateTimeFormat('es-PE', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    }).format(date);
  } catch {
    return String(dateInput);
  }
}

/**
 * Formatea una fecha y hora al estándar peruano
 */
export function formatDateTimePE(dateInput: string | Date | undefined | null): string {
  if (!dateInput) return '-';
  try {
    const date = typeof dateInput === 'string' ? new Date(dateInput) : dateInput;
    if (isNaN(date.getTime())) return String(dateInput);
    return new Intl.DateTimeFormat('es-PE', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    }).format(date);
  } catch {
    return String(dateInput);
  }
}

/**
 * Formatea una nota en la escala vigesimal peruana (0.00 a 20.00)
 * Regla académica nacional: Nota mínima aprobatoria es 10.50 (redondeada a 11 en acta final)
 */
export function formatGrade(score: number): {
  scoreFormatted: string;
  isPassing: boolean;
  statusLabel: string;
} {
  const num = typeof score === 'number' ? score : Number(score);
  const safeScore = isNaN(num) ? 0 : num;
  const isPassing = safeScore >= 10.5;

  return {
    scoreFormatted: safeScore.toFixed(2),
    isPassing,
    statusLabel: isPassing ? 'APROBADO' : 'DESAPROBADO',
  };
}
