-- ============================================================
-- DATASET V2 SEEDS: finance_db
-- 4 Conceptos, 5 Métodos, 4 Estados, 20 Órdenes y 20 Pagos
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE finance_db;

CREATE TABLE IF NOT EXISTS payment_concepts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payment_methods (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payment_statuses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payment_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(36) NOT NULL,
    enrollment_id INT NULL,
    concept_id INT NOT NULL,
    status_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    due_date DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_orders_student (student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payment_order_id INT NOT NULL,
    method_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    transaction_ref VARCHAR(100) NOT NULL UNIQUE,
    idempotency_key VARCHAR(100) NOT NULL UNIQUE,
    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1. Catálogos Maestros de Pagos
INSERT INTO payment_concepts (id, code, name, amount) VALUES
(1, 'MAT-ORD', 'Matrícula Ordinaria', 350.00),
(2, 'PEN-01', 'Pensión Mensual 1', 650.00),
(3, 'CER-EST', 'Certificado de Estudios', 50.00),
(4, 'CAR-EST', 'Carné Universitario', 30.00)
ON DUPLICATE KEY UPDATE name = VALUES(name), amount = VALUES(amount);

INSERT INTO payment_methods (id, code, name) VALUES
(1, 'CASH', 'Efectivo en Ventanilla'),
(2, 'CARD', 'Tarjeta de Crédito/Débito'),
(3, 'TRANSFER', 'Transferencia Bancaria Interbancaria'),
(4, 'YAPE', 'Billetera Digital Yape'),
(5, 'PLIN', 'Billetera Digital Plin')
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO payment_statuses (id, code, name) VALUES
(1, 'PENDING', 'Pendiente de Pago'),
(2, 'PAID', 'Pagado y Conciliado'),
(3, 'OVERDUE', 'Vencido'),
(4, 'ANNULLED', 'Anulado')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- 2. 20 Órdenes de Pago (Matrícula S/ 350.00 y Pensión S/ 650.00 por alumno)
INSERT INTO payment_orders (id, student_id, enrollment_id, concept_id, status_id, amount, due_date) VALUES
-- Alumno 1 (alu01)
(1, '018f0001-0000-7000-8000-000000000002', 1, 1, 2, 350.00, '2026-03-31'),
(2, '018f0001-0000-7000-8000-000000000002', 1, 2, 2, 650.00, '2026-04-30'),
-- Alumno 2 (alu02)
(3, '018f0001-0000-7000-8000-000000000012', 2, 1, 2, 350.00, '2026-03-31'),
(4, '018f0001-0000-7000-8000-000000000012', 2, 2, 2, 650.00, '2026-04-30'),
-- Alumno 3 (alu03)
(5, '018f0001-0000-7000-8000-000000000013', 3, 1, 2, 350.00, '2026-03-31'),
(6, '018f0001-0000-7000-8000-000000000013', 3, 2, 2, 650.00, '2026-04-30'),
-- Alumno 4 (alu04)
(7, '018f0001-0000-7000-8000-000000000014', 4, 1, 2, 350.00, '2026-03-31'),
(8, '018f0001-0000-7000-8000-000000000014', 4, 2, 2, 650.00, '2026-04-30'),
-- Alumno 5 (alu05)
(9, '018f0001-0000-7000-8000-000000000015', 5, 1, 2, 350.00, '2026-03-31'),
(10, '018f0001-0000-7000-8000-000000000015', 5, 2, 2, 650.00, '2026-04-30'),
-- Alumno 6 (alu06)
(11, '018f0001-0000-7000-8000-000000000016', 6, 1, 2, 350.00, '2026-03-31'),
(12, '018f0001-0000-7000-8000-000000000016', 6, 2, 2, 650.00, '2026-04-30'),
-- Alumno 7 (alu07)
(13, '018f0001-0000-7000-8000-000000000017', 7, 1, 2, 350.00, '2026-03-31'),
(14, '018f0001-0000-7000-8000-000000000017', 7, 2, 2, 650.00, '2026-04-30'),
-- Alumno 8 (alu08)
(15, '018f0001-0000-7000-8000-000000000018', 8, 1, 2, 350.00, '2026-03-31'),
(16, '018f0001-0000-7000-8000-000000000018', 8, 2, 2, 650.00, '2026-04-30'),
-- Alumno 9 (alu09)
(17, '018f0001-0000-7000-8000-000000000019', 9, 1, 2, 350.00, '2026-03-31'),
(18, '018f0001-0000-7000-8000-000000000019', 9, 2, 2, 650.00, '2026-04-30'),
-- Alumno 10 (alu10)
(19, '018f0001-0000-7000-8000-000000000020', 10, 1, 2, 350.00, '2026-03-31'),
(20, '018f0001-0000-7000-8000-000000000020', 10, 2, 2, 650.00, '2026-04-30')
ON DUPLICATE KEY UPDATE status_id = VALUES(status_id), amount = VALUES(amount), due_date = VALUES(due_date);

-- 3. 20 Pagos Conciliados
INSERT INTO payments (id, payment_order_id, method_id, amount, transaction_ref, idempotency_key, paid_at) VALUES
(1, 1, 3, 350.00, 'TRX-2026-0001', 'idemp-pay-0001', '2026-03-11 11:00:00'),
(2, 2, 3, 650.00, 'TRX-2026-0002', 'idemp-pay-0002', '2026-04-12 11:00:00'),
(3, 3, 3, 350.00, 'TRX-2026-0003', 'idemp-pay-0003', '2026-03-13 11:00:00'),
(4, 4, 3, 650.00, 'TRX-2026-0004', 'idemp-pay-0004', '2026-04-14 11:00:00'),
(5, 5, 3, 350.00, 'TRX-2026-0005', 'idemp-pay-0005', '2026-03-15 11:00:00'),
(6, 6, 3, 650.00, 'TRX-2026-0006', 'idemp-pay-0006', '2026-04-16 11:00:00'),
(7, 7, 3, 350.00, 'TRX-2026-0007', 'idemp-pay-0007', '2026-03-17 11:00:00'),
(8, 8, 3, 650.00, 'TRX-2026-0008', 'idemp-pay-0008', '2026-04-18 11:00:00'),
(9, 9, 3, 350.00, 'TRX-2026-0009', 'idemp-pay-0009', '2026-03-19 11:00:00'),
(10, 10, 3, 650.00, 'TRX-2026-0010', 'idemp-pay-0010', '2026-04-10 11:00:00'),
(11, 11, 3, 350.00, 'TRX-2026-0011', 'idemp-pay-0011', '2026-03-11 11:00:00'),
(12, 12, 3, 650.00, 'TRX-2026-0012', 'idemp-pay-0012', '2026-04-12 11:00:00'),
(13, 13, 3, 350.00, 'TRX-2026-0013', 'idemp-pay-0013', '2026-03-13 11:00:00'),
(14, 14, 3, 650.00, 'TRX-2026-0014', 'idemp-pay-0014', '2026-04-14 11:00:00'),
(15, 15, 3, 350.00, 'TRX-2026-0015', 'idemp-pay-0015', '2026-03-15 11:00:00'),
(16, 16, 3, 650.00, 'TRX-2026-0016', 'idemp-pay-0016', '2026-04-16 11:00:00'),
(17, 17, 3, 350.00, 'TRX-2026-0017', 'idemp-pay-0017', '2026-03-17 11:00:00'),
(18, 18, 3, 650.00, 'TRX-2026-0018', 'idemp-pay-0018', '2026-04-18 11:00:00'),
(19, 19, 3, 350.00, 'TRX-2026-0019', 'idemp-pay-0019', '2026-03-19 11:00:00'),
(20, 20, 3, 650.00, 'TRX-2026-0020', 'idemp-pay-0020', '2026-04-10 11:00:00')
ON DUPLICATE KEY UPDATE amount = VALUES(amount), paid_at = VALUES(paid_at);
