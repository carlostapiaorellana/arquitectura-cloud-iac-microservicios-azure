-- ============================================================
-- MIGRACIÓN V001: Estructura de Tablas para person_db
-- Contexto Delimitado: Personas, Perfiles y Catálogos Demográficos
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE person_db;

-- 1. Catálogos Demográficos y Laborales
CREATE TABLE IF NOT EXISTS tipodocumento (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(30) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sexo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(30) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS distrito (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS estadocivil (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS gradoinstruccion (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS areaempleo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cargo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    estado BIT NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- 2. Entidad Estudiantes (Alumnos)
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
    INDEX idx_students_auth_user (auth_user_id),
    INDEX idx_students_code (student_code),
    INDEX idx_students_doc (document_number),
    CONSTRAINT fk_students_district FOREIGN KEY (district_id) REFERENCES distrito(id),
    CONSTRAINT fk_students_gender FOREIGN KEY (gender_id) REFERENCES sexo(id),
    CONSTRAINT fk_students_doc_type FOREIGN KEY (document_type_id) REFERENCES tipodocumento(id),
    CONSTRAINT fk_students_civil_status FOREIGN KEY (civil_status_id) REFERENCES estadocivil(id)
) ENGINE=InnoDB;

-- 3. Entidad Docentes
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
    INDEX idx_teachers_auth_user (auth_user_id),
    INDEX idx_teachers_code (teacher_code),
    INDEX idx_teachers_doc (document_number),
    CONSTRAINT fk_teachers_district FOREIGN KEY (district_id) REFERENCES distrito(id),
    CONSTRAINT fk_teachers_gender FOREIGN KEY (gender_id) REFERENCES sexo(id),
    CONSTRAINT fk_teachers_doc_type FOREIGN KEY (document_type_id) REFERENCES tipodocumento(id),
    CONSTRAINT fk_teachers_civil_status FOREIGN KEY (civil_status_id) REFERENCES estadocivil(id)
) ENGINE=InnoDB;

-- 4. Entidad Empleados (Personal Administrativo)
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
    INDEX idx_employees_auth_user (auth_user_id),
    INDEX idx_employees_code (employee_code),
    INDEX idx_employees_doc (document_number),
    CONSTRAINT fk_employees_area FOREIGN KEY (area_id) REFERENCES areaempleo(id),
    CONSTRAINT fk_employees_position FOREIGN KEY (position_id) REFERENCES cargo(id),
    CONSTRAINT fk_employees_district FOREIGN KEY (district_id) REFERENCES distrito(id),
    CONSTRAINT fk_employees_gender FOREIGN KEY (gender_id) REFERENCES sexo(id),
    CONSTRAINT fk_employees_doc_type FOREIGN KEY (document_type_id) REFERENCES tipodocumento(id),
    CONSTRAINT fk_employees_civil_status FOREIGN KEY (civil_status_id) REFERENCES estadocivil(id)
) ENGINE=InnoDB;
