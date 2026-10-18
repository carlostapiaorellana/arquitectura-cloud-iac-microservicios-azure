-- ============================================================
-- DATASET V2 SEEDS: enrollment_db
-- 10 Matrículas, 20 Detalles, 40 Calificaciones Vigesimales y Asistencias
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE enrollment_db;

CREATE TABLE IF NOT EXISTS enrollment_statuses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS enrollment_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS grade_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE,
    weight DECIMAL(3,2) NOT NULL DEFAULT 1.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS enrollments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(36) NOT NULL,
    academic_period_id INT NOT NULL,
    enrollment_status_id INT,
    enrollment_type_id INT,
    observations TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_enrollments_student (student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS enrollment_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT NOT NULL,
    section_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'ENROLLED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_enrollment_details_section (section_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS grades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_detail_id INT NOT NULL,
    grade_type_id INT NOT NULL,
    score DECIMAL(5,2) NOT NULL,
    graded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_grades_detail (enrollment_detail_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_detail_id INT NOT NULL,
    session_date DATE NOT NULL,
    is_present BOOLEAN NOT NULL,
    is_justified BOOLEAN NOT NULL DEFAULT FALSE,
    INDEX idx_attendance_detail (enrollment_detail_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS transfers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(36) NOT NULL,
    source_program_id INT,
    target_program_id INT,
    academic_period_id INT,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_transfers_student (student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1. Catálogos Base
INSERT INTO enrollment_statuses (id, name) VALUES
(1, 'Registrada'), (2, 'Confirmada'), (3, 'Observada'), (4, 'Anulada')
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO enrollment_types (id, name) VALUES
(1, 'Regular'), (2, 'Extemporánea'), (3, 'Traslado'), (4, 'Reingreso')
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO grade_types (id, name, weight) VALUES
(1, 'Práctica Calificada', 0.20),
(2, 'Examen Parcial', 0.40),
(3, 'Trabajo Académico', 0.20),
(4, 'Examen Final', 0.40)
ON DUPLICATE KEY UPDATE weight = VALUES(weight);

-- 2. 10 Matrículas Ordinarias 2026-I
INSERT INTO enrollments (id, student_id, academic_period_id, enrollment_status_id, enrollment_type_id, observations) VALUES
(1, '018f0001-0000-7000-8000-000000000002', 1, 2, 1, 'Matrícula regular 2026-I'),
(2, '018f0001-0000-7000-8000-000000000012', 1, 2, 1, 'Matrícula regular 2026-I'),
(3, '018f0001-0000-7000-8000-000000000013', 1, 2, 1, 'Matrícula regular 2026-I'),
(4, '018f0001-0000-7000-8000-000000000014', 1, 2, 1, 'Matrícula regular 2026-I'),
(5, '018f0001-0000-7000-8000-000000000015', 1, 2, 1, 'Matrícula regular 2026-I'),
(6, '018f0001-0000-7000-8000-000000000016', 1, 2, 1, 'Matrícula regular 2026-I'),
(7, '018f0001-0000-7000-8000-000000000017', 1, 2, 1, 'Matrícula regular 2026-I'),
(8, '018f0001-0000-7000-8000-000000000018', 1, 2, 1, 'Matrícula regular 2026-I'),
(9, '018f0001-0000-7000-8000-000000000019', 1, 2, 1, 'Matrícula regular 2026-I'),
(10, '018f0001-0000-7000-8000-000000000020', 1, 2, 1, 'Matrícula regular 2026-I')
ON DUPLICATE KEY UPDATE observations = VALUES(observations);

-- 3. 20 Detalles de Asignación a Secciones
INSERT INTO enrollment_details (id, enrollment_id, section_id, status) VALUES
(1, 1, 1, 'ENROLLED'), (2, 1, 2, 'ENROLLED'),
(3, 2, 2, 'ENROLLED'), (4, 2, 3, 'ENROLLED'),
(5, 3, 3, 'ENROLLED'), (6, 3, 4, 'ENROLLED'),
(7, 4, 4, 'ENROLLED'), (8, 4, 5, 'ENROLLED'),
(9, 5, 5, 'ENROLLED'), (10, 5, 6, 'ENROLLED'),
(11, 6, 6, 'ENROLLED'), (12, 6, 7, 'ENROLLED'),
(13, 7, 7, 'ENROLLED'), (14, 7, 8, 'ENROLLED'),
(15, 8, 8, 'ENROLLED'), (16, 8, 9, 'ENROLLED'),
(17, 9, 9, 'ENROLLED'), (18, 9, 10, 'ENROLLED'),
(19, 10, 10, 'ENROLLED'), (20, 10, 1, 'ENROLLED')
ON DUPLICATE KEY UPDATE status = VALUES(status);

-- 4. 40 Calificaciones Oficiales en Escala Vigesimal (12 a 20)
INSERT INTO grades (id, enrollment_detail_id, grade_type_id, score, graded_at) VALUES
(1, 1, 1, 13.00, '2026-05-11 10:00:00'),
(2, 1, 2, 14.00, '2026-06-11 10:00:00'),
(3, 2, 1, 14.00, '2026-05-12 10:00:00'),
(4, 2, 2, 15.00, '2026-06-12 10:00:00'),
(5, 3, 1, 15.00, '2026-05-13 10:00:00'),
(6, 3, 2, 16.00, '2026-06-13 10:00:00'),
(7, 4, 1, 16.00, '2026-05-14 10:00:00'),
(8, 4, 2, 17.00, '2026-06-14 10:00:00'),
(9, 5, 1, 17.00, '2026-05-15 10:00:00'),
(10, 5, 2, 18.00, '2026-06-15 10:00:00'),
(11, 6, 1, 18.00, '2026-05-16 10:00:00'),
(12, 6, 2, 19.00, '2026-06-16 10:00:00'),
(13, 7, 1, 19.00, '2026-05-17 10:00:00'),
(14, 7, 2, 20.00, '2026-06-17 10:00:00'),
(15, 8, 1, 12.00, '2026-05-18 10:00:00'),
(16, 8, 2, 13.00, '2026-06-18 10:00:00'),
(17, 9, 1, 13.00, '2026-05-19 10:00:00'),
(18, 9, 2, 14.00, '2026-06-19 10:00:00'),
(19, 10, 1, 14.00, '2026-05-10 10:00:00'),
(20, 10, 2, 15.00, '2026-06-10 10:00:00'),
(21, 11, 1, 15.00, '2026-05-11 10:00:00'),
(22, 11, 2, 16.00, '2026-06-11 10:00:00'),
(23, 12, 1, 16.00, '2026-05-12 10:00:00'),
(24, 12, 2, 17.00, '2026-06-12 10:00:00'),
(25, 13, 1, 17.00, '2026-05-13 10:00:00'),
(26, 13, 2, 18.00, '2026-06-13 10:00:00'),
(27, 14, 1, 18.00, '2026-05-14 10:00:00'),
(28, 14, 2, 19.00, '2026-06-14 10:00:00'),
(29, 15, 1, 19.00, '2026-05-15 10:00:00'),
(30, 15, 2, 20.00, '2026-06-15 10:00:00'),
(31, 16, 1, 12.00, '2026-05-16 10:00:00'),
(32, 16, 2, 13.00, '2026-06-16 10:00:00'),
(33, 17, 1, 13.00, '2026-05-17 10:00:00'),
(34, 17, 2, 14.00, '2026-06-17 10:00:00'),
(35, 18, 1, 14.00, '2026-05-18 10:00:00'),
(36, 18, 2, 15.00, '2026-06-18 10:00:00'),
(37, 19, 1, 15.00, '2026-05-19 10:00:00'),
(38, 19, 2, 16.00, '2026-06-19 10:00:00'),
(39, 20, 1, 16.00, '2026-05-10 10:00:00'),
(40, 20, 2, 17.00, '2026-06-10 10:00:00')
ON DUPLICATE KEY UPDATE score = VALUES(score), graded_at = VALUES(graded_at);

-- 5. Control de Asistencias Representativas
INSERT INTO attendance (id, enrollment_detail_id, session_date, is_present, is_justified) VALUES
(1, 1, '2026-04-06', 1, 0), (2, 1, '2026-04-13', 1, 0), (3, 1, '2026-04-20', 1, 0),
(4, 2, '2026-04-06', 1, 0), (5, 2, '2026-04-13', 1, 0), (6, 2, '2026-04-20', 1, 0),
(7, 3, '2026-04-06', 1, 0), (8, 3, '2026-04-13', 1, 0), (9, 3, '2026-04-20', 1, 0),
(10, 4, '2026-04-06', 1, 0), (11, 4, '2026-04-13', 1, 0), (12, 4, '2026-04-20', 1, 0),
(13, 5, '2026-04-06', 1, 0), (14, 5, '2026-04-13', 1, 0), (15, 5, '2026-04-20', 1, 0),
(16, 6, '2026-04-06', 1, 0), (17, 6, '2026-04-13', 1, 0), (18, 6, '2026-04-20', 1, 0),
(19, 7, '2026-04-06', 1, 0), (20, 7, '2026-04-13', 1, 0), (21, 7, '2026-04-20', 0, 0),
(22, 8, '2026-04-06', 1, 0), (23, 8, '2026-04-13', 0, 1), (24, 8, '2026-04-20', 1, 0),
(25, 9, '2026-04-06', 0, 0), (26, 9, '2026-04-13', 1, 0), (27, 9, '2026-04-20', 1, 0),
(28, 10, '2026-04-06', 1, 0), (29, 10, '2026-04-13', 1, 0), (30, 10, '2026-04-20', 1, 0),
(31, 11, '2026-04-06', 1, 0), (32, 11, '2026-04-13', 1, 0), (33, 11, '2026-04-20', 1, 0),
(34, 12, '2026-04-06', 1, 0), (35, 12, '2026-04-13', 1, 0), (36, 12, '2026-04-20', 1, 0),
(37, 13, '2026-04-06', 1, 0), (38, 13, '2026-04-13', 1, 0), (39, 13, '2026-04-20', 1, 0),
(40, 14, '2026-04-06', 1, 0), (41, 14, '2026-04-13', 1, 0), (42, 14, '2026-04-20', 1, 0),
(43, 15, '2026-04-06', 1, 0), (44, 15, '2026-04-13', 1, 0), (45, 15, '2026-04-20', 1, 0),
(46, 16, '2026-04-06', 1, 0), (47, 16, '2026-04-13', 1, 0), (48, 16, '2026-04-20', 0, 1),
(49, 17, '2026-04-06', 1, 0), (50, 17, '2026-04-13', 0, 0), (51, 17, '2026-04-20', 1, 0),
(52, 18, '2026-04-06', 0, 1), (53, 18, '2026-04-13', 1, 0), (54, 18, '2026-04-20', 1, 0),
(55, 19, '2026-04-06', 1, 0), (56, 19, '2026-04-13', 1, 0), (57, 19, '2026-04-20', 1, 0),
(58, 20, '2026-04-06', 1, 0), (59, 20, '2026-04-13', 1, 0), (60, 20, '2026-04-20', 1, 0)
ON DUPLICATE KEY UPDATE is_present = VALUES(is_present);

-- 6. Traslados Académicos
INSERT INTO transfers (id, student_id, source_program_id, target_program_id, academic_period_id, status) VALUES
(1, '018f0001-0000-7000-8000-000000000013', 1, 2, 1, 'COMPLETED'),
(2, '018f0001-0000-7000-8000-000000000018', 3, 1, 1, 'COMPLETED')
ON DUPLICATE KEY UPDATE status = VALUES(status);
