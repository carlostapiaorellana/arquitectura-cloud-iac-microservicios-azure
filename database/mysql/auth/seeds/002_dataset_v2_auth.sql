-- ============================================================
-- DATASET V2 SEEDS: auth_db
-- 7 Roles Institucionales y 22 Usuarios con Hash Bcrypt
-- Contraseña universal: 'password123'
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE auth_db;

CREATE TABLE IF NOT EXISTS roles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at DATETIME NOT NULL,
    revoked_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_refresh_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1. Roles Institucionales
INSERT INTO roles (id, name, description) VALUES
(1, 'ADMIN', 'Administrador con control total de la plataforma'),
(2, 'STUDENT', 'Estudiante universitario con acceso a portal y matriculas'),
(3, 'TEACHER', 'Docente titular o contratado con gestion de notas y asistencias'),
(4, 'SECRETARY', 'Secretaría Académica para trámites y convalidaciones'),
(5, 'TREASURY', 'Tesorería y Finanzas para gestión de pagos y recaudaciones'),
(6, 'LIBRARY', 'Gestión bibliotecaria y préstamos documentales'),
(7, 'COORDINATOR', 'Coordinador Académico de Facultad')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- 2. 22 Usuarios Institucionales (10 Alumnos, 6 Docentes, 6 Empleados)
-- Hash Bcrypt para 'password123': $2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG
INSERT INTO users (id, username, email, password_hash, role_id, status) VALUES
-- 10 Alumnos (alu01 - alu10)
('018f0001-0000-7000-8000-000000000002', 'alu01', 'juan.ramirez@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000012', 'alu02', 'maria.torres@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000013', 'alu03', 'luis.mendoza@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000014', 'alu04', 'andrea.flores@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000015', 'alu05', 'pedro.castillo@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000016', 'alu06', 'lucia.garcia@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000017', 'alu07', 'carlos.sanchez@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000018', 'alu08', 'sofia.rojas@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000019', 'alu09', 'diego.vega@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000020', 'alu10', 'valentina.herrera@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE'),

-- 6 Docentes (doc01 - doc06)
('018f0001-0000-7000-8000-000000000003', 'doc01', 'mario.huapalla@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 3, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000022', 'doc02', 'patricia.salazar@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 3, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000023', 'doc03', 'jorge.mendoza@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 3, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000024', 'doc04', 'claudia.fernandez@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 3, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000025', 'doc05', 'ricardo.torres@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 3, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000026', 'doc06', 'ana.rojas@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 3, 'ACTIVE'),

-- 6 Empleados Administrativos (emp01 - emp06)
('018f0001-0000-7000-8000-000000000031', 'emp01', 'roberto.orue@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 1, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000032', 'emp02', 'julia.mendoza@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 4, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000033', 'emp03', 'carlos.vargas@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 5, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000034', 'emp04', 'rosa.paredes@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 6, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000035', 'emp05', 'miguel.castro@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 1, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000036', 'emp06', 'elena.flores@unfpg.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 4, 'ACTIVE')
ON DUPLICATE KEY UPDATE 
    username = VALUES(username),
    email = VALUES(email),
    password_hash = VALUES(password_hash),
    role_id = VALUES(role_id),
    status = VALUES(status);
