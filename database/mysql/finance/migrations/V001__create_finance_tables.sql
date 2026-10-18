-- ============================================================
-- MIGRACIÓN V001: Estructura de Tablas para finance_db
-- Contexto Delimitado: Gestión Financiera, Órdenes de Pago y Transacciones
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE finance_db;

-- 1. Catálogos Maestros de Pagos
CREATE TABLE IF NOT EXISTS payment_concepts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payment_methods (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payment_statuses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Tablas Transaccionales
CREATE TABLE IF NOT EXISTS payment_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(36) NOT NULL,
    enrollment_id INT NULL,
    concept_id INT NOT NULL,
    status_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    due_date DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_orders_student (student_id),
    CONSTRAINT fk_orders_concept FOREIGN KEY (concept_id) REFERENCES payment_concepts(id),
    CONSTRAINT fk_orders_status FOREIGN KEY (status_id) REFERENCES payment_statuses(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payment_order_id INT NOT NULL,
    method_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    transaction_ref VARCHAR(100) NOT NULL UNIQUE,
    idempotency_key VARCHAR(100) NOT NULL UNIQUE,
    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payments_order FOREIGN KEY (payment_order_id) REFERENCES payment_orders(id),
    CONSTRAINT fk_payments_method FOREIGN KEY (method_id) REFERENCES payment_methods(id)
) ENGINE=InnoDB;
