-- ============================================================
-- DATASET V2 SEEDS: academic_db
-- 3 Facultades, 4 Programas, 10 Cursos, 8 Aulas, 10 Secciones y 12 Horarios
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE academic_db;

CREATE TABLE IF NOT EXISTS faculties (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS academic_periods (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS blocks (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS weekdays (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL UNIQUE,
    short_name VARCHAR(5) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS classroom_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS locations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    address VARCHAR(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS classroom_statuses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS programs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    faculty_id INT NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    degree VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS study_plans (
    id INT PRIMARY KEY AUTO_INCREMENT,
    program_id INT NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS courses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    program_id INT NOT NULL,
    sercur VARCHAR(20) NOT NULL UNIQUE,
    nomcur VARCHAR(100) NOT NULL,
    crecur INT NOT NULL,
    blocur VARCHAR(20) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS classrooms (
    id INT PRIMARY KEY AUTO_INCREMENT,
    classroom_type_id INT NOT NULL,
    location_id INT NOT NULL,
    status_id INT NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    capacity INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    academic_period_id INT NOT NULL,
    code VARCHAR(20) NOT NULL,
    teacher_id VARCHAR(36) NULL,
    capacity INT NOT NULL DEFAULT 40,
    enrolled INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sections_teacher (teacher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS schedules (
    id INT PRIMARY KEY AUTO_INCREMENT,
    section_id INT NOT NULL,
    block_id INT NOT NULL,
    weekday_id INT NOT NULL,
    classroom_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1. Catálogos Base
INSERT INTO faculties (id, code, name) VALUES
(1, 'FAC-ING', 'Ingeniería y Tecnología'),
(2, 'FAC-EMP', 'Ciencias Empresariales'),
(3, 'FAC-HUM', 'Humanidades y Educación')
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO academic_periods (id, name, start_date, end_date, is_active) VALUES
(1, '2026-I', '2026-03-16', '2026-07-18', 1),
(2, '2026-II', '2026-08-17', '2026-12-19', 0)
ON DUPLICATE KEY UPDATE is_active = VALUES(is_active);

INSERT INTO blocks (id, name, start_time, end_time) VALUES
(1, 'B1', '08:00:00', '09:30:00'),
(2, 'B2', '09:45:00', '11:15:00'),
(3, 'B3', '11:30:00', '13:00:00'),
(4, 'B4', '14:00:00', '15:30:00'),
(5, 'B5', '15:45:00', '17:15:00'),
(6, 'B6', '18:00:00', '19:30:00'),
(7, 'B7', '19:45:00', '21:15:00')
ON DUPLICATE KEY UPDATE start_time = VALUES(start_time), end_time = VALUES(end_time);

INSERT INTO weekdays (id, name, short_name) VALUES
(1, 'Lunes', 'LUN'), (2, 'Martes', 'MAR'), (3, 'Miércoles', 'MIE'),
(4, 'Jueves', 'JUE'), (5, 'Viernes', 'VIE'), (6, 'Sábado', 'SAB'), (7, 'Domingo', 'DOM')
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO classroom_types (id, name) VALUES
(1, 'Aula Teórica'), (2, 'Laboratorio de Cómputo'),
(3, 'Laboratorio Especializado'), (4, 'Auditorio')
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO locations (id, name, address) VALUES
(1, 'Pabellón A - Primer Piso', 'Área de aulas generales'),
(2, 'Pabellón A - Segundo Piso', 'Área académica'),
(3, 'Pabellón B - Primer Piso', 'Laboratorios de cómputo'),
(4, 'Pabellón C', 'Auditorios y salas especializadas')
ON DUPLICATE KEY UPDATE address = VALUES(address);

INSERT INTO classroom_statuses (id, name) VALUES
(1, 'Disponible'), (2, 'Ocupada'), (3, 'Mantenimiento'), (4, 'Inhabilitada')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- 2. Carreras / Programas Académicos y Planes de Estudio
INSERT INTO programs (id, faculty_id, code, name, degree) VALUES
(1, 1, 'SIS', 'Ingeniería de Sistemas', 'Bachiller en Ingeniería de Sistemas'),
(2, 1, 'SFT', 'Ingeniería de Software', 'Bachiller en Ingeniería de Software'),
(3, 2, 'ADM', 'Administración de Empresas', 'Bachiller en Administración de Empresas'),
(4, 3, 'EDU', 'Educación', 'Bachiller en Educación')
ON DUPLICATE KEY UPDATE name = VALUES(name), degree = VALUES(degree);

INSERT INTO study_plans (id, program_id, code, name, year, is_active) VALUES
(1, 1, 'PLA-SIS-2026', 'Plan 2026 - Ingeniería de Sistemas', 2026, 1),
(2, 2, 'PLA-SFT-2026', 'Plan 2026 - Ingeniería de Software', 2026, 1),
(3, 3, 'PLA-ADM-2026', 'Plan 2026 - Administración', 2026, 1),
(4, 4, 'PLA-EDU-2026', 'Plan 2026 - Educación', 2026, 1)
ON DUPLICATE KEY UPDATE is_active = VALUES(is_active);

-- 3. 10 Cursos Oficiales del Dataset v2
INSERT INTO courses (id, program_id, sercur, nomcur, crecur, blocur) VALUES
(1, 1, 'IS101', 'Fundamentos de Programación', 4, 'B1'),
(2, 1, 'IS102', 'Base de Datos I', 4, 'B1'),
(3, 1, 'IS103', 'Arquitectura de Computadoras', 3, 'B2'),
(4, 1, 'IS104', 'Redes de Computadoras', 4, 'B2'),
(5, 2, 'SW101', 'Ingeniería de Software I', 4, 'B1'),
(6, 2, 'SW102', 'Desarrollo Web', 4, 'B2'),
(7, 3, 'AD101', 'Fundamentos de Administración', 3, 'B1'),
(8, 3, 'AD102', 'Contabilidad General', 4, 'B2'),
(9, 4, 'ED101', 'Fundamentos de Educación', 3, 'B1'),
(10, 4, 'ED102', 'Tecnología Educativa', 4, 'B2')
ON DUPLICATE KEY UPDATE nomcur = VALUES(nomcur), crecur = VALUES(crecur), blocur = VALUES(blocur);

-- 4. Ambientes / Aulas Físicas
INSERT INTO classrooms (id, classroom_type_id, location_id, status_id, code, capacity) VALUES
(1, 1, 1, 1, 'A-101', 35),
(2, 1, 1, 1, 'A-102', 35),
(3, 1, 2, 1, 'A-201', 40),
(4, 2, 3, 1, 'LAB-01', 30),
(5, 2, 3, 1, 'LAB-02', 30),
(6, 3, 3, 1, 'LAB-03', 25),
(7, 4, 4, 1, 'AUD-01', 100),
(8, 1, 2, 1, 'A-202', 40)
ON DUPLICATE KEY UPDATE capacity = VALUES(capacity);

-- 5. 10 Secciones Académicas con Docente Asignado
INSERT INTO sections (id, course_id, academic_period_id, code, teacher_id, capacity, enrolled) VALUES
(1, 1, 1, 'SEC-IS101-A', '018f0001-0000-7000-8000-000000000003', 30, 2),
(2, 2, 1, 'SEC-IS102-A', '018f0001-0000-7000-8000-000000000023', 30, 2),
(3, 3, 1, 'SEC-IS103-A', '018f0001-0000-7000-8000-000000000025', 30, 2),
(4, 4, 1, 'SEC-IS104-A', '018f0001-0000-7000-8000-000000000025', 30, 2),
(5, 5, 1, 'SEC-SW101-A', '018f0001-0000-7000-8000-000000000023', 30, 2),
(6, 6, 1, 'SEC-SW102-A', '018f0001-0000-7000-8000-000000000003', 30, 2),
(7, 7, 1, 'SEC-AD101-A', '018f0001-0000-7000-8000-000000000024', 35, 2),
(8, 8, 1, 'SEC-AD102-A', '018f0001-0000-7000-8000-000000000024', 35, 2),
(9, 9, 1, 'SEC-ED101-A', '018f0001-0000-7000-8000-000000000026', 30, 2),
(10, 10, 1, 'SEC-ED102-A', '018f0001-0000-7000-8000-000000000026', 30, 2)
ON DUPLICATE KEY UPDATE capacity = VALUES(capacity), enrolled = VALUES(enrolled);

-- 6. 12 Horarios de Clases
INSERT INTO schedules (id, section_id, block_id, weekday_id, classroom_id) VALUES
(1, 1, 1, 1, 4), (2, 1, 2, 3, 4),
(3, 2, 1, 2, 5), (4, 2, 2, 4, 5),
(5, 3, 3, 1, 1),
(6, 4, 3, 2, 2),
(7, 5, 4, 3, 1),
(8, 6, 4, 4, 4),
(9, 7, 5, 1, 3),
(10, 8, 5, 2, 3),
(11, 9, 6, 3, 8),
(12, 10, 6, 4, 8)
ON DUPLICATE KEY UPDATE block_id = VALUES(block_id), weekday_id = VALUES(weekday_id), classroom_id = VALUES(classroom_id);
