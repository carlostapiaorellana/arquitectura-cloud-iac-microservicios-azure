import React from 'react';
import { cn } from '../../utils/cn';

export interface SkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
  className?: string;
}

export const Skeleton: React.FC<SkeletonProps> = ({ className, ...props }) => {
  return (
    <div
      className={cn('animate-pulse rounded bg-slate-200 dark:bg-slate-800', className)}
      {...props}
    />
  );
};

export interface CardSkeletonProps {
  className?: string;
}

export const CardSkeleton: React.FC<CardSkeletonProps> = ({ className }) => {
  return (
    <div
      className={cn(
        'rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900',
        className
      )}
    >
      <div className="flex items-start gap-4">
        <Skeleton className="h-12 w-12 rounded-xl" />
        <div className="flex-1 space-y-3">
          <Skeleton className="h-4 w-3/4" />
          <Skeleton className="h-3 w-1/2" />
          <div className="flex gap-2 pt-2">
            <Skeleton className="h-6 w-20 rounded-full" />
            <Skeleton className="h-6 w-24 rounded-full" />
          </div>
        </div>
      </div>
    </div>
  );
};

export interface TableRowSkeletonProps {
  columns?: number;
  className?: string;
}

export const TableRowSkeleton: React.FC<TableRowSkeletonProps> = ({
  columns = 5,
  className,
}) => {
  return (
    <tr className={cn('animate-pulse border-b border-slate-100 dark:border-slate-800/60', className)}>
      {Array.from({ length: columns }).map((_, idx) => (
        <td key={idx} className="py-4 px-3">
          <Skeleton className="h-4 w-full max-w-[120px]" />
        </td>
      ))}
    </tr>
  );
};
