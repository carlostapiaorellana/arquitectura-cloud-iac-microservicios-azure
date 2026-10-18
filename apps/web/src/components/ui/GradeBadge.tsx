import React from 'react';
import { cn } from '../../utils/cn';

export interface GradeBadgeProps {
  score: number;
  showScore?: boolean;
  showLabel?: boolean;
  className?: string;
}

export const GradeBadge: React.FC<GradeBadgeProps> = ({
  score,
  showScore = true,
  showLabel = true,
  className,
}) => {
  const numericScore = typeof score === 'number' ? score : Number(score) || 0;
  const formattedScore = numericScore.toFixed(2);

  let styleClasses = '';
  let label = '';

  if (numericScore >= 14.0) {
    styleClasses = 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20';
    label = 'Sobresaliente';
  } else if (numericScore >= 10.5) {
    styleClasses = 'bg-teal-500/10 text-teal-600 dark:text-teal-400 border border-teal-500/20';
    label = 'Aprobado';
  } else {
    styleClasses = 'bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-500/20';
    label = 'Desaprobado';
  }

  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold tracking-wide transition-colors',
        styleClasses,
        className
      )}
    >
      {showScore && <span className="font-mono">{formattedScore}</span>}
      {showScore && showLabel && <span className="opacity-60">·</span>}
      {showLabel && <span>{label}</span>}
    </span>
  );
};
