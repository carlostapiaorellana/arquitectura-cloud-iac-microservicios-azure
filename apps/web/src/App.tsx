import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
import { AcademicLmsPage } from './pages/AcademicLmsPage';
import { EnrollmentGradesPage } from './pages/EnrollmentGradesPage';
import { FinancePaymentsPage } from './pages/FinancePaymentsPage';
import { LibraryCatalogPage } from './pages/LibraryCatalogPage';
import { AppShell } from './components/layout/AppShell';
import { ProtectedRoute } from './components/layout/ProtectedRoute';

export const App: React.FC = () => {
  return (
    <Routes>
      {/* Ruta Pública: Acceso Institucional */}
      <Route path="/login" element={<LoginPage />} />

      {/* Rutas Privadas / Protegidas por Zero-Trust Guard */}
      <Route
        element={
          <ProtectedRoute>
            <AppShell />
          </ProtectedRoute>
        }
      >
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/academico" element={<AcademicLmsPage />} />
        <Route path="/lms" element={<Navigate to="/academico" replace />} />
        <Route path="/matricula-notas" element={<EnrollmentGradesPage />} />
        <Route path="/pagos" element={<FinancePaymentsPage />} />
        <Route path="/biblioteca" element={<LibraryCatalogPage />} />
      </Route>

      {/* Redirección por defecto */}
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
};
