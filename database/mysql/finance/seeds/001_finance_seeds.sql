-- ============================================================
-- SEEDS: Datos Semilla Iniciales para finance_db
-- Contexto Delimitado: Catálogos Financieros y Órdenes Demo para alu01
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE finance_db;

-- 1. Catálogo de Conceptos de Pago
INSERT INTO payment_concepts (id, code, name, amount) VALUES
(1, 'MAT-ORD', 'Matricula Ordinaria', 350.00),
(2, 'PEN-01', 'Cuota Pension 1', 850.00),
(3, 'CAR-EST', 'Carne Universitario', 30.00),
(4, 'CON-EST', 'Constancia de Estudios', 25.00)
ON DUPLICATE KEY UPDATE name = VALUES(name), amount = VALUES(amount);

-- 2. Catálogo de Métodos de Pago
INSERT INTO payment_methods (id, code, name) VALUES
(1, 'CARD', 'Tarjeta de Credito/Debito'),
(2, 'TRANSFER', 'Transferencia Bancaria'),
(3, 'COUNTER', 'Pago en Ventanilla'),
(4, 'WALLET', 'Billetera Digital')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- 3. Catálogo de Estados de Pago
INSERT INTO payment_statuses (id, code, name) VALUES
(1, 'PENDING', 'Pendiente de Pago'),
(2, 'PAID', 'Pagado'),
(3, 'OVERDUE', 'Vencido'),
(4, 'ANNULLED', 'Anulado')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- 4. Órdenes de Pago Semilla para el Estudiante Demo (alu01)
-- student_id: '018f0001-0000-7000-8000-000000000002'
INSERT INTO payment_orders (id, student_id, enrollment_id, concept_id, status_id, amount, due_date) VALUES
(1, '018f0001-0000-7000-8000-000000000002', 1, 1, 1, 350.00, '2026-04-30'),
(2, '018f0001-0000-7000-8000-000000000002', 1, 2, 1, 850.00, '2026-05-31')
ON DUPLICATE KEY UPDATE
    student_id = VALUES(student_id),
    enrollment_id = VALUES(enrollment_id),
    concept_id = VALUES(concept_id),
    status_id = VALUES(status_id),
    amount = VALUES(amount),
    due_date = VALUES(due_date);
