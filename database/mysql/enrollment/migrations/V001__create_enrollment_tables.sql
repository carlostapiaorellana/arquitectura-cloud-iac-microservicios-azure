-- ============================================================
-- MIGRACIÓN V001: Estructura de Tablas para enrollment_db
-- Contexto Delimitado: Matrículas, Evaluaciones, Asistencias y Convalidaciones
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE enrollment_db;

-- 1. Catálogos Operativos de Matrícula y Evaluación
CREATE TABLE IF NOT EXISTS enrollment_statuses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS enrollment_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS grade_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE,
    weight DECIMAL(3,2) NOT NULL DEFAULT 1.00
) ENGINE=InnoDB;

-- 2. Entidad Transaccional Matrículas
CREATE TABLE IF NOT EXISTS enrollments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(36) NOT NULL,
    academic_period_id INT NOT NULL,
    enrollment_status_id INT,
    enrollment_type_id INT,
    observations TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_enrollments_student (student_id),
    INDEX idx_enrollments_period (academic_period_id),
    CONSTRAINT fk_enrollments_status FOREIGN KEY (enrollment_status_id) REFERENCES enrollment_statuses(id),
    CONSTRAINT fk_enrollments_type FOREIGN KEY (enrollment_type_id) REFERENCES enrollment_types(id)
) ENGINE=InnoDB;

-- 3. Detalle de Secciones Matriculadas
CREATE TABLE IF NOT EXISTS enrollment_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT NOT NULL,
    section_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'ENROLLED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_enrollment_details_section (section_id),
    CONSTRAINT fk_enrollment_details_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. Registro de Calificaciones
CREATE TABLE IF NOT EXISTS grades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_detail_id INT NOT NULL,
    grade_type_id INT NOT NULL,
    score DECIMAL(5,2) NOT NULL,
    graded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_grades_detail (enrollment_detail_id),
    CONSTRAINT fk_grades_detail FOREIGN KEY (enrollment_detail_id) REFERENCES enrollment_details(id) ON DELETE CASCADE,
    CONSTRAINT fk_grades_type FOREIGN KEY (grade_type_id) REFERENCES grade_types(id)
) ENGINE=InnoDB;

-- 5. Control de Asistencias
CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_detail_id INT NOT NULL,
    session_date DATE NOT NULL,
    is_present BOOLEAN NOT NULL,
    is_justified BOOLEAN NOT NULL DEFAULT FALSE,
    INDEX idx_attendance_detail (enrollment_detail_id),
    CONSTRAINT fk_attendance_detail FOREIGN KEY (enrollment_detail_id) REFERENCES enrollment_details(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. Traslados de Programa
CREATE TABLE IF NOT EXISTS transfers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(36) NOT NULL,
    source_program_id INT,
    target_program_id INT,
    academic_period_id INT,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_transfers_student (student_id)
) ENGINE=InnoDB;
