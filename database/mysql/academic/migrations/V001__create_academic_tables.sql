-- ============================================================
-- MIGRACIÓN V001: Estructura de Tablas para academic_db
-- Contexto Delimitado: Gestión Curricular, Facultades, Cursos, Aulas y Secciones
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE academic_db;

-- 1. Catálogos Maestros de Infraestructura y Horarios
CREATE TABLE IF NOT EXISTS faculties (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS academic_periods (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS blocks (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS weekdays (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL UNIQUE,
    short_name VARCHAR(5) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS classroom_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS locations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    address VARCHAR(200) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS classroom_statuses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 2. Estructura Académica (Programas, Planes de Estudio, Cursos)
CREATE TABLE IF NOT EXISTS programs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    faculty_id INT NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    degree VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_programs_faculty FOREIGN KEY (faculty_id) REFERENCES faculties(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS study_plans (
    id INT PRIMARY KEY AUTO_INCREMENT,
    program_id INT NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_study_plans_program FOREIGN KEY (program_id) REFERENCES programs(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS courses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    program_id INT NOT NULL,
    sercur VARCHAR(20) NOT NULL UNIQUE,
    nomcur VARCHAR(100) NOT NULL,
    crecur INT NOT NULL,
    blocur VARCHAR(20) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_courses_program FOREIGN KEY (program_id) REFERENCES programs(id)
) ENGINE=InnoDB;

-- 3. Ambientes Físicos y Secciones
CREATE TABLE IF NOT EXISTS classrooms (
    id INT PRIMARY KEY AUTO_INCREMENT,
    classroom_type_id INT NOT NULL,
    location_id INT NOT NULL,
    status_id INT NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    capacity INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_classrooms_type FOREIGN KEY (classroom_type_id) REFERENCES classroom_types(id),
    CONSTRAINT fk_classrooms_location FOREIGN KEY (location_id) REFERENCES locations(id),
    CONSTRAINT fk_classrooms_status FOREIGN KEY (status_id) REFERENCES classroom_statuses(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    academic_period_id INT NOT NULL,
    code VARCHAR(20) NOT NULL,
    teacher_id VARCHAR(36) NULL,
    capacity INT NOT NULL DEFAULT 40,
    enrolled INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sections_teacher (teacher_id),
    CONSTRAINT uq_section_course_period UNIQUE (course_id, academic_period_id, code),
    CONSTRAINT fk_sections_course FOREIGN KEY (course_id) REFERENCES courses(id),
    CONSTRAINT fk_sections_period FOREIGN KEY (academic_period_id) REFERENCES academic_periods(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS schedules (
    id INT PRIMARY KEY AUTO_INCREMENT,
    section_id INT NOT NULL,
    block_id INT NOT NULL,
    weekday_id INT NOT NULL,
    classroom_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_schedules_section FOREIGN KEY (section_id) REFERENCES sections(id),
    CONSTRAINT fk_schedules_block FOREIGN KEY (block_id) REFERENCES blocks(id),
    CONSTRAINT fk_schedules_weekday FOREIGN KEY (weekday_id) REFERENCES weekdays(id),
    CONSTRAINT fk_schedules_classroom FOREIGN KEY (classroom_id) REFERENCES classrooms(id)
) ENGINE=InnoDB;
