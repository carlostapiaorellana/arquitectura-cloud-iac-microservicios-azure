-- ============================================================
-- SEEDS: Datos Semilla Idempotentes para auth_db
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE auth_db;

-- 1. Roles Base del Sistema
INSERT INTO roles (id, name, description) VALUES
(1, 'ADMIN', 'Administrador con control total de la plataforma'),
(2, 'STUDENT', 'Estudiante universitario con acceso a portal y matriculas'),
(3, 'TEACHER', 'Docente titular o contratado con gestion de notas y asistencias'),
(4, 'EMPLOYEE', 'Personal administrativo y operativo')
ON DUPLICATE KEY UPDATE name = VALUES(name), description = VALUES(description);

-- 2. Usuarios Demo con Hash Bcrypt Válido (Contraseña: 'password123')
-- Hash: $2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG
INSERT INTO users (id, username, email, password_hash, role_id, status) VALUES
('018f0001-0000-7000-8000-000000000001', 'admin', 'admin@universidad.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 1, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000002', 'alu01', 'estudiante1@universidad.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000003', 'docente1', 'docente1@universidad.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 3, 'ACTIVE'),
('018f0001-0000-7000-8000-000000000004', 'estudiante1', 'estudiante.demo@universidad.edu.pe', '$2a$10$cLBOWjMS7eay.AQE5hExz.RLwwERIYTq2vgu7rtp3PaCND3tApmCG', 2, 'ACTIVE')
ON DUPLICATE KEY UPDATE username = VALUES(username), email = VALUES(email), password_hash = VALUES(password_hash), role_id = VALUES(role_id), status = VALUES(status);
