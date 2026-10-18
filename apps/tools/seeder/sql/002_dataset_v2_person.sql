-- ============================================================
-- DATASET V2 SEEDS: person_db
-- 7 Catálogos, 10 Estudiantes, 6 Docentes y 6 Empleados
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE person_db;

CREATE TABLE IF NOT EXISTS tipodocumento (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(30) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sexo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(30) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS distrito (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS estadocivil (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS gradoinstruccion (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS areaempleo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cargo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS students (
    id VARCHAR(36) PRIMARY KEY,
    student_code VARCHAR(20) NOT NULL UNIQUE,
    auth_user_id VARCHAR(36) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name_father VARCHAR(40) NOT NULL,
    last_name_mother VARCHAR(40) NOT NULL,
    birth_date DATE NOT NULL,
    document_number VARCHAR(20) NOT NULL UNIQUE,
    nationality VARCHAR(20) NOT NULL DEFAULT 'Peruana',
    address TEXT NOT NULL,
    phone VARCHAR(15) NULL,
    mobile VARCHAR(15) NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    district_id INT NOT NULL,
    gender_id INT NOT NULL,
    document_type_id INT NOT NULL,
    civil_status_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_students_auth_user (auth_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS teachers (
    id VARCHAR(36) PRIMARY KEY,
    teacher_code VARCHAR(20) NOT NULL UNIQUE,
    auth_user_id VARCHAR(36) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name_father VARCHAR(40) NOT NULL,
    last_name_mother VARCHAR(40) NOT NULL,
    birth_date DATE NOT NULL,
    document_number VARCHAR(20) NOT NULL UNIQUE,
    nationality VARCHAR(20) NOT NULL DEFAULT 'Peruana',
    address TEXT NOT NULL,
    phone VARCHAR(15) NULL,
    mobile VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    salary DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    district_id INT NOT NULL,
    gender_id INT NOT NULL,
    document_type_id INT NOT NULL,
    civil_status_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_teachers_auth_user (auth_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS employees (
    id VARCHAR(36) PRIMARY KEY,
    employee_code VARCHAR(20) NOT NULL UNIQUE,
    auth_user_id VARCHAR(36) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name_father VARCHAR(40) NOT NULL,
    last_name_mother VARCHAR(40) NOT NULL,
    birth_date DATE NOT NULL,
    document_number VARCHAR(20) NOT NULL UNIQUE,
    nationality VARCHAR(20) NOT NULL DEFAULT 'Peruana',
    address TEXT NOT NULL,
    phone VARCHAR(15) NULL,
    mobile VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    salary DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    area_id INT NOT NULL,
    position_id INT NOT NULL,
    district_id INT NOT NULL,
    gender_id INT NOT NULL,
    document_type_id INT NOT NULL,
    civil_status_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_employees_auth_user (auth_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1. Catálogos Demográficos y Laborales
INSERT IGNORE INTO tipodocumento (id, nombre, estado) VALUES
(1, 'DNI', 1), (2, 'Pasaporte', 1), (3, 'Carnet Extranjería', 1), (4, 'RUC', 1), (5, 'Licencia de Conducir', 1);

INSERT IGNORE INTO sexo (id, nombre, estado) VALUES
(1, 'Masculino', 1), (2, 'Femenino', 1), (3, 'No Binario', 1), (4, 'Otro', 1), (5, 'Prefiere no decir', 1);

INSERT IGNORE INTO estadocivil (id, nombre, estado) VALUES
(1, 'Soltero(a)', 1), (2, 'Casado(a)', 1), (3, 'Viudo(a)', 1), (4, 'Divorciado(a)', 1);

INSERT IGNORE INTO gradoinstruccion (id, nombre, estado) VALUES
(1, 'Bachiller', 1), (2, 'Título Profesional', 1), (3, 'Maestría', 1), (4, 'Doctorado', 1);

INSERT IGNORE INTO areaempleo (id, nombre, estado) VALUES
(1, 'Administración', 1), (2, 'Secretaría Académica', 1), (3, 'Tesorería', 1), (4, 'Biblioteca', 1), (5, 'Tecnologías de Información', 1), (6, 'Servicios Generales', 1);

INSERT IGNORE INTO cargo (id, nombre, estado) VALUES
(1, 'Director Administrativo', 1), (2, 'Secretario Académico', 1), (3, 'Tesorero', 1), (4, 'Bibliotecario', 1), (5, 'Analista de Sistemas', 1), (6, 'Asistente Administrativo', 1);

INSERT IGNORE INTO distrito (id, nombre, estado) VALUES
(1, 'Ancón', 1), (2, 'Ate', 1), (3, 'Barranco', 1), (4, 'Breña', 1), (5, 'Carabayllo', 1),
(6, 'Chaclacayo', 1), (7, 'Chorrillos', 1), (8, 'Cieneguilla', 1), (9, 'Comas', 1), (10, 'El Agustino', 1),
(11, 'Independencia', 1), (12, 'Jesús María', 1), (13, 'La Molina', 1), (14, 'La Victoria', 1), (15, 'Lima', 1),
(16, 'Lince', 1), (17, 'Los Olivos', 1), (18, 'Lurigancho', 1), (19, 'Lurín', 1), (20, 'Magdalena del Mar', 1),
(21, 'Miraflores', 1), (22, 'Pachacámac', 1), (23, 'Pucusana', 1), (24, 'Pueblo Libre', 1), (25, 'Puente Piedra', 1),
(26, 'Punta Hermosa', 1), (27, 'Punta Negra', 1), (28, 'Rímac', 1), (29, 'San Bartolo', 1), (30, 'San Borja', 1),
(31, 'San Isidro', 1), (32, 'San Juan de Lurigancho', 1), (33, 'San Juan de Miraflores', 1), (34, 'San Luis', 1), (35, 'San Martín de Porres', 1),
(36, 'San Miguel', 1), (37, 'Santa Anita', 1), (38, 'Santa María del Mar', 1), (39, 'Santa Rosa', 1), (40, 'Santiago de Surco', 1),
(41, 'Surquillo', 1), (42, 'Villa El Salvador', 1), (43, 'Villa María del Triunfo', 1), (44, 'Callao', 1), (45, 'Bellavista', 1),
(46, 'Carmen de La Legua-Reynoso', 1), (47, 'La Perla', 1), (48, 'La Punta', 1), (49, 'Ventanilla', 1), (50, 'Mi Perú', 1);

-- 2. 10 Estudiantes Universitarios Vinculados a auth_user_id
INSERT INTO students (
    id, student_code, auth_user_id, first_name, last_name_father, last_name_mother,
    birth_date, document_number, nationality, address, phone, mobile,
    email, status, district_id, gender_id, document_type_id, civil_status_id
) VALUES
('018f0001-0000-7000-9000-000000000002', 'ALU-2026-0001', '018f0001-0000-7000-8000-000000000002', 'Juan Carlos', 'Ramirez', 'Lopez', '2005-03-15', '78000001', 'Peruana', 'Av. Los Próceres 123 - San Juan de Lurigancho', '014500001', '900100001', 'juan.ramirez@unfpg.edu.pe', 'ACTIVE', 32, 1, 1, 1),
('018f0001-0000-7000-9000-000000000012', 'ALU-2026-0002', '018f0001-0000-7000-8000-000000000012', 'Maria Fernanda', 'Torres', 'Diaz', '2004-07-22', '78000002', 'Peruana', 'Jr. Las Gardenias 456 - Jesús María', '014500002', '900100002', 'maria.torres@unfpg.edu.pe', 'ACTIVE', 12, 2, 1, 1),
('018f0001-0000-7000-9000-000000000013', 'ALU-2026-0003', '018f0001-0000-7000-8000-000000000013', 'Luis Alberto', 'Mendoza', 'Rios', '2003-11-10', '78000003', 'Peruana', 'Av. Universitaria 789 - Los Olivos', '014500003', '900100003', 'luis.mendoza@unfpg.edu.pe', 'ACTIVE', 17, 1, 1, 1),
('018f0001-0000-7000-9000-000000000014', 'ALU-2026-0004', '018f0001-0000-7000-8000-000000000014', 'Andrea Valeria', 'Flores', 'Soto', '2005-01-30', '78000004', 'Peruana', 'Calle Los Cedros 321 - Ate', '014500004', '900100004', 'andrea.flores@unfpg.edu.pe', 'ACTIVE', 2, 2, 1, 1),
('018f0001-0000-7000-9000-000000000015', 'ALU-2026-0005', '018f0001-0000-7000-8000-000000000015', 'Pedro Miguel', 'Castillo', 'Perez', '2004-09-18', '78000005', 'Peruana', 'Av. Central 555 - Comas', '014500005', '900100005', 'pedro.castillo@unfpg.edu.pe', 'ACTIVE', 9, 1, 1, 1),
('018f0001-0000-7000-9000-000000000016', 'ALU-2026-0006', '018f0001-0000-7000-8000-000000000016', 'Lucia Daniela', 'Garcia', 'Vargas', '2006-04-05', '78000006', 'Peruana', 'Jr. San Martín 222 - Lima', '014500006', '900100006', 'lucia.garcia@unfpg.edu.pe', 'ACTIVE', 15, 2, 1, 1),
('018f0001-0000-7000-9000-000000000017', 'ALU-2026-0007', '018f0001-0000-7000-8000-000000000017', 'Carlos Eduardo', 'Sanchez', 'Morales', '2003-12-12', '78000007', 'Peruana', 'Av. Primavera 888 - Santiago de Surco', '014500007', '900100007', 'carlos.sanchez@unfpg.edu.pe', 'ACTIVE', 40, 1, 1, 1),
('018f0001-0000-7000-9000-000000000018', 'ALU-2026-0008', '018f0001-0000-7000-8000-000000000018', 'Sofia Camila', 'Rojas', 'Fernandez', '2005-06-27', '78000008', 'Peruana', 'Calle Los Pinos 444 - San Miguel', '014500008', '900100008', 'sofia.rojas@unfpg.edu.pe', 'ACTIVE', 36, 2, 1, 1),
('018f0001-0000-7000-9000-000000000019', 'ALU-2026-0009', '018f0001-0000-7000-8000-000000000019', 'Diego Armando', 'Vega', 'Castro', '2004-02-14', '78000009', 'Peruana', 'Av. Grau 999 - La Victoria', '014500009', '900100009', 'diego.vega@unfpg.edu.pe', 'ACTIVE', 14, 1, 1, 1),
('018f0001-0000-7000-9000-000000000020', 'ALU-2026-0010', '018f0001-0000-7000-8000-000000000020', 'Valentina', 'Herrera', 'Campos', '2006-08-09', '78000010', 'Peruana', 'Jr. Los Rosales 101 - Miraflores', '014500010', '900100010', 'valentina.herrera@unfpg.edu.pe', 'ACTIVE', 21, 2, 1, 1)
ON DUPLICATE KEY UPDATE
    first_name = VALUES(first_name),
    last_name_father = VALUES(last_name_father),
    last_name_mother = VALUES(last_name_mother),
    email = VALUES(email),
    address = VALUES(address),
    status = VALUES(status);

-- 3. 6 Docentes Universitarios Vinculados a auth_user_id
INSERT INTO teachers (
    id, teacher_code, auth_user_id, first_name, last_name_father, last_name_mother,
    birth_date, document_number, nationality, address, phone, mobile,
    email, salary, status, district_id, gender_id, document_type_id, civil_status_id
) VALUES
('018f0001-0000-7000-9000-000000000003', 'DOC-2026-0001', '018f0001-0000-7000-8000-000000000003', 'Mario Antonio', 'Huapalla', 'Morales', '1980-02-10', '70000001', 'Peruana', 'Av. Universitaria 100', '014600001', '910200001', 'mario.huapalla@unfpg.edu.pe', 4500.00, 'ACTIVE', 15, 1, 1, 2),
('018f0001-0000-7000-9000-000000000022', 'DOC-2026-0002', '018f0001-0000-7000-8000-000000000022', 'Patricia Elena', 'Salazar', 'Ramos', '1982-06-18', '70000002', 'Peruana', 'Av. Arequipa 1200', '014600002', '910200002', 'patricia.salazar@unfpg.edu.pe', 4200.00, 'ACTIVE', 12, 2, 1, 2),
('018f0001-0000-7000-9000-000000000023', 'DOC-2026-0003', '018f0001-0000-7000-8000-000000000023', 'Jorge Luis', 'Mendoza', 'Castro', '1978-09-05', '70000003', 'Peruana', 'Jr. Lima 320', '014600003', '910200003', 'jorge.mendoza@unfpg.edu.pe', 4800.00, 'ACTIVE', 17, 1, 1, 2),
('018f0001-0000-7000-9000-000000000024', 'DOC-2026-0004', '018f0001-0000-7000-8000-000000000024', 'Claudia Rosa', 'Fernandez', 'Vega', '1985-01-22', '70000004', 'Peruana', 'Av. Benavides 450', '014600004', '910200004', 'claudia.fernandez@unfpg.edu.pe', 4100.00, 'ACTIVE', 21, 2, 1, 1),
('018f0001-0000-7000-9000-000000000025', 'DOC-2026-0005', '018f0001-0000-7000-8000-000000000025', 'Ricardo José', 'Torres', 'Flores', '1981-11-30', '70000005', 'Peruana', 'Av. Brasil 800', '014600005', '910200005', 'ricardo.torres@unfpg.edu.pe', 4400.00, 'ACTIVE', 24, 1, 1, 2),
('018f0001-0000-7000-9000-000000000026', 'DOC-2026-0006', '018f0001-0000-7000-8000-000000000026', 'Ana María', 'Rojas', 'Soto', '1986-04-14', '70000006', 'Peruana', 'Calle Central 200', '014600006', '910200006', 'ana.rojas@unfpg.edu.pe', 4000.00, 'ACTIVE', 30, 2, 1, 1)
ON DUPLICATE KEY UPDATE
    first_name = VALUES(first_name),
    last_name_father = VALUES(last_name_father),
    last_name_mother = VALUES(last_name_mother),
    email = VALUES(email),
    salary = VALUES(salary),
    status = VALUES(status);

-- 4. 6 Empleados Administrativos Vinculados a auth_user_id
INSERT INTO employees (
    id, employee_code, auth_user_id, first_name, last_name_father, last_name_mother,
    birth_date, document_number, nationality, address, phone, mobile,
    email, salary, status, area_id, position_id, district_id, gender_id, document_type_id, civil_status_id
) VALUES
('018f0001-0000-7000-9000-000000000031', 'EMP-2026-0001', '018f0001-0000-7000-8000-000000000031', 'Roberto', 'Orue', 'Bustamante', '1975-05-10', '72000001', 'Peruana', 'Av. Arequipa 1201', '014700001', '920300001', 'roberto.orue@unfpg.edu.pe', 5000.00, 'ACTIVE', 1, 1, 15, 1, 1, 2),
('018f0001-0000-7000-9000-000000000032', 'EMP-2026-0002', '018f0001-0000-7000-8000-000000000032', 'Julia', 'Mendoza', 'Ramos', '1988-08-21', '72000002', 'Peruana', 'Jr. Central 220', '014700002', '920300002', 'julia.mendoza@unfpg.edu.pe', 2800.00, 'ACTIVE', 2, 2, 12, 2, 1, 1),
('018f0001-0000-7000-9000-000000000033', 'EMP-2026-0003', '018f0001-0000-7000-8000-000000000033', 'Carlos', 'Vargas', 'León', '1984-03-11', '72000003', 'Peruana', 'Av. Colonial 410', '014700003', '920300003', 'carlos.vargas@unfpg.edu.pe', 3200.00, 'ACTIVE', 3, 3, 44, 1, 1, 2),
('018f0001-0000-7000-9000-000000000034', 'EMP-2026-0004', '018f0001-0000-7000-8000-000000000034', 'Rosa', 'Paredes', 'Díaz', '1990-07-17', '72000004', 'Peruana', 'Av. La Marina 350', '014700004', '920300004', 'rosa.paredes@unfpg.edu.pe', 2600.00, 'ACTIVE', 4, 4, 36, 2, 1, 1),
('018f0001-0000-7000-9000-000000000035', 'EMP-2026-0005', '018f0001-0000-7000-8000-000000000035', 'Miguel', 'Castro', 'Reyes', '1987-12-02', '72000005', 'Peruana', 'Av. Universitaria 500', '014700005', '920300005', 'miguel.castro@unfpg.edu.pe', 3800.00, 'ACTIVE', 5, 5, 17, 1, 1, 2),
('018f0001-0000-7000-9000-000000000036', 'EMP-2026-0006', '018f0001-0000-7000-8000-000000000036', 'Elena', 'Flores', 'Campos', '1992-09-14', '72000006', 'Peruana', 'Jr. Los Olivos 150', '014700006', '920300006', 'elena.flores@unfpg.edu.pe', 2400.00, 'ACTIVE', 1, 6, 9, 2, 1, 1)
ON DUPLICATE KEY UPDATE
    first_name = VALUES(first_name),
    last_name_father = VALUES(last_name_father),
    last_name_mother = VALUES(last_name_mother),
    email = VALUES(email),
    salary = VALUES(salary),
    status = VALUES(status);
