import React, { useState, useEffect } from 'react';
import {
  BookOpen,
  Search,
  CheckCircle,
  Tag,
  Clock,
  BookmarkCheck,
  AlertCircle,
  RefreshCw,
  Library,
  BookCopy,
} from 'lucide-react';
import { useBooksQuery, useMyLoansQuery } from '../hooks/useLibrary';
import { CardSkeleton, Skeleton } from '../components/ui/Skeleton';
import { formatDatePE } from '../utils/formatters';

export const LibraryCatalogPage: React.FC = () => {
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [debouncedSearch, setDebouncedSearch] = useState<string>('');

  // Debounce de 300ms sobre el término de búsqueda
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(searchTerm);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  const categoryParam = selectedCategory === 'ALL' ? undefined : selectedCategory;
  const booksQuery = useBooksQuery(categoryParam);
  const loansQuery = useMyLoansQuery();

  const isLoading = booksQuery.isLoading;
  const isError = booksQuery.isError;
  const books = booksQuery.data || [];
  const loans = loansQuery.data || [];

  // Categorías fijadas para el catálogo universitario
  const categories = [
    { id: 'ALL', label: 'Todos los Libros' },
    { id: 'Informatica', label: 'Informática & Cloud' },
    { id: 'Software', label: 'Ingeniería de Software' },
    { id: 'Sistemas', label: 'Arquitectura de Sistemas' },
  ];

  // Filtro local adicional por el debouncedSearch (título, autor, ISBN)
  const filteredBooks = books.filter((book) => {
    if (!debouncedSearch.trim()) return true;
    const term = debouncedSearch.toLowerCase();
    return (
      book.title.toLowerCase().includes(term) ||
      book.author.toLowerCase().includes(term) ||
      book.isbn.toLowerCase().includes(term)
    );
  });

  return (
    <div className="space-y-8">
      {/* Encabezado Principal */}
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <h2 className="font-display text-xl font-bold text-slate-900 dark:text-white">
            Biblioteca Documental NoSQL
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Catálogo bibliográfico distribuido en DynamoDB / Azure Cosmos DB y préstamos académicos.
          </p>
        </div>
        <button
          type="button"
          onClick={() => {
            booksQuery.refetch();
            loansQuery.refetch();
          }}
          className="inline-flex items-center gap-1.5 self-start rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 shadow-sm hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-900 dark:text-slate-300"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${isLoading ? 'animate-spin' : ''}`} />
          <span>Sincronizar Catálogo</span>
        </button>
      </div>

      {/* Sección 1: Mis Préstamos Activos */}
      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
        <div className="flex items-center justify-between border-b border-slate-200 pb-4 dark:border-slate-800">
          <div className="flex items-center gap-3">
            <div className="rounded-xl bg-cyan-500/10 p-2.5 text-cyan-600 dark:text-cyan-400">
              <BookmarkCheck className="h-5 w-5" />
            </div>
            <div>
              <h3 className="font-display text-sm font-bold text-slate-900 dark:text-white">
                Mis Préstamos Activos
              </h3>
              <p className="text-xs text-slate-500">
                Préstamos físicos y virtuales en curso asociados a su carné universitario.
              </p>
            </div>
          </div>
          <span className="rounded-full bg-cyan-500/10 px-3 py-1 font-mono text-xs font-bold text-cyan-600 dark:text-cyan-400">
            {loans.length} activo(s)
          </span>
        </div>

        <div className="mt-4">
          {loansQuery.isLoading && loans.length === 0 && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Skeleton className="h-24 w-full rounded-xl" />
            </div>
          )}

          {!loansQuery.isLoading && loans.length === 0 && (
            <div className="rounded-lg border border-dashed border-slate-200 p-6 text-center text-xs text-slate-500 dark:border-slate-800">
              No registra préstamos de libros pendientes de devolución en este periodo.
            </div>
          )}

          {loans.length > 0 && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {loans.map((loan) => (
                <div
                  key={loan.id}
                  className="rounded-xl border border-slate-200 bg-slate-50/50 p-4 shadow-sm dark:border-slate-800 dark:bg-slate-800/40"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="space-y-1">
                      <span className="font-mono text-[10px] text-slate-400 block">
                        ID Préstamo: {loan.id}
                      </span>
                      <h4 className="font-display text-sm font-bold text-slate-900 dark:text-white">
                        {loan.bookTitle}
                      </h4>
                    </div>
                    <span className="inline-flex items-center gap-1 rounded-full bg-emerald-500/10 px-2.5 py-0.5 text-xs font-semibold text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
                      <Clock className="h-3 w-3" /> {loan.status}
                    </span>
                  </div>

                  <div className="mt-3 flex items-center justify-between border-t border-slate-200/60 pt-3 text-xs text-slate-500 dark:border-slate-700/60">
                    <span>
                      Retiro: <span className="font-medium text-slate-700 dark:text-slate-300">{formatDatePE(loan.loanDate)}</span>
                    </span>
                    <span>
                      Devolución Límite:{' '}
                      <span className="font-bold text-amber-600 dark:text-amber-400">
                        {formatDatePE(loan.dueDate)}
                      </span>
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Sección 2: Buscador y Filtros del Catálogo */}
      <div className="space-y-4">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          {/* Pestañas de Categoría */}
          <div className="flex flex-wrap gap-2">
            {categories.map((cat) => (
              <button
                key={cat.id}
                type="button"
                onClick={() => setSelectedCategory(cat.id)}
                className={`rounded-lg px-3.5 py-1.5 text-xs font-semibold transition-all ${
                  selectedCategory === cat.id
                    ? 'bg-brand-blue-600 text-white shadow-sm'
                    : 'bg-white border border-slate-200 text-slate-600 hover:bg-slate-50 dark:bg-slate-900 dark:border-slate-800 dark:text-slate-300 dark:hover:bg-slate-800'
                }`}
              >
                {cat.label}
              </button>
            ))}
          </div>

          {/* Caja de Búsqueda en Vivo */}
          <div className="relative w-full md:w-80">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Buscar título, autor o ISBN..."
              className="w-full rounded-xl border border-slate-200 bg-white py-2 pl-9 pr-4 text-xs text-slate-900 shadow-sm focus:border-brand-blue-500 focus:outline-none dark:border-slate-800 dark:bg-slate-900 dark:text-white"
            />
            {debouncedSearch && (
              <span className="absolute right-3 top-2.5 font-mono text-[10px] text-slate-400">
                Filtro activo
              </span>
            )}
          </div>
        </div>

        {/* Error */}
        {isError && (
          <div className="flex items-center gap-3 rounded-xl border border-rose-500/20 bg-rose-500/10 p-4 text-xs text-rose-700 dark:text-rose-400">
            <AlertCircle className="h-5 w-5 flex-shrink-0" />
            <span>Error al conectar con la base de datos de biblioteca (library-service).</span>
          </div>
        )}

        {/* Skeletons */}
        {isLoading && filteredBooks.length === 0 && (
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
            <CardSkeleton />
            <CardSkeleton />
            <CardSkeleton />
          </div>
        )}

        {/* Grid de Libros */}
        {!isLoading && filteredBooks.length === 0 && (
          <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-slate-300 p-12 text-center dark:border-slate-800">
            <Library className="h-10 w-10 text-slate-400" />
            <h3 className="mt-3 font-display text-sm font-bold text-slate-800 dark:text-slate-200">
              No se encontraron libros en esta categoría
            </h3>
            <p className="mt-1 text-xs text-slate-500">
              Intente con otro término de búsqueda o seleccione otra categoría.
            </p>
          </div>
        )}

        {filteredBooks.length > 0 && (
          <div className="grid grid-cols-1 gap-5 md:grid-cols-2 lg:grid-cols-3">
            {filteredBooks.map((book) => {
              const hasCopies = book.availableCopies > 0;

              return (
                <div
                  key={book.id}
                  className="flex flex-col justify-between rounded-xl border border-slate-200 bg-white p-5 shadow-sm hover:border-cyan-400 hover:shadow-md transition-all dark:border-slate-800 dark:bg-slate-900"
                >
                  <div className="space-y-3">
                    <div className="flex items-start gap-3">
                      <div className="rounded-xl bg-cyan-500/10 p-3 text-cyan-600 dark:text-cyan-400 flex-shrink-0">
                        <BookOpen className="h-6 w-6" />
                      </div>
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="inline-flex items-center gap-1 rounded bg-slate-100 px-2 py-0.5 text-[10px] font-semibold text-slate-600 dark:bg-slate-800 dark:text-slate-400">
                            <Tag className="h-2.5 w-2.5" /> {book.category}
                          </span>
                        </div>
                        <h4 className="font-display text-sm font-bold text-slate-900 dark:text-white line-clamp-2">
                          {book.title}
                        </h4>
                        <p className="text-xs text-slate-500 dark:text-slate-400">
                          {book.author}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center justify-between border-t border-slate-100 pt-3 text-xs dark:border-slate-800/80">
                      <span className="font-mono text-[10px] text-slate-400">
                        ISBN: {book.isbn}
                      </span>
                      <div
                        className={`inline-flex items-center gap-1.5 font-medium ${
                          hasCopies
                            ? 'text-emerald-600 dark:text-emerald-400'
                            : 'text-rose-500 dark:text-rose-400'
                        }`}
                      >
                        {hasCopies ? (
                          <CheckCircle className="h-3.5 w-3.5" />
                        ) : (
                          <BookCopy className="h-3.5 w-3.5" />
                        )}
                        <span>
                          {book.availableCopies} de {book.totalCopies} disponibles
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="mt-4 pt-3 border-t border-slate-100 dark:border-slate-800">
                    <button
                      type="button"
                      disabled={!hasCopies}
                      className="w-full rounded-lg bg-cyan-600/10 px-3 py-2 text-xs font-bold text-cyan-600 hover:bg-cyan-600 hover:text-white dark:bg-cyan-500/20 dark:text-cyan-300 dark:hover:bg-cyan-600 dark:hover:text-white disabled:opacity-40 disabled:hover:bg-cyan-600/10 disabled:hover:text-cyan-600 transition-all active:scale-98"
                    >
                      {hasCopies ? 'Solicitar Préstamo' : 'Sin Ejemplares Disponibles'}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};
