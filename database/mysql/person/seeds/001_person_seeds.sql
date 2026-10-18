-- ============================================================
-- SEEDS: Datos Semilla Idempotentes para person_db
-- Extraídos de bduniversidad datos v2.sql
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE person_db;

-- 1. Catálogos Demográficos y Laborales
INSERT IGNORE INTO tipodocumento (id, nombre, estado) VALUES
(1, 'DNI', 1),
(2, 'Pasaporte', 1),
(3, 'Carnet Extranjería', 1),
(4, 'RUC', 1),
(5, 'Licencia de Conducir', 1);

INSERT IGNORE INTO sexo (id, nombre, estado) VALUES
(1, 'Masculino', 1),
(2, 'Femenino', 1),
(3, 'No Binario', 1),
(4, 'Otro', 1),
(5, 'Prefiere no decir', 1);

INSERT IGNORE INTO estadocivil (id, nombre, estado) VALUES
(1, 'Soltero(a)', 1),
(2, 'Casado(a)', 1),
(3, 'Viudo(a)', 1),
(4, 'Divorciado(a)', 1);

INSERT IGNORE INTO gradoinstruccion (id, nombre, estado) VALUES
(1, 'Bachiller', 1),
(2, 'Título Profesional', 1),
(3, 'Maestría', 1),
(4, 'Doctorado', 1);

INSERT IGNORE INTO areaempleo (id, nombre, estado) VALUES
(1, 'Administración', 1),
(2, 'Secretaría Académica', 1),
(3, 'Tesorería', 1),
(4, 'Biblioteca', 1),
(5, 'Tecnologías de Información', 1),
(6, 'Servicios Generales', 1);

INSERT IGNORE INTO cargo (id, nombre, estado) VALUES
(1, 'Director Administrativo', 1),
(2, 'Secretario Académico', 1),
(3, 'Tesorero', 1),
(4, 'Bibliotecario', 1),
(5, 'Analista de Sistemas', 1),
(6, 'Asistente Administrativo', 1);

INSERT IGNORE INTO distrito (id, nombre, estado) VALUES
(1, 'Ancón', 1), (2, 'Ate', 1), (3, 'Barranco', 1), (4, 'Breña', 1),
(5, 'Carabayllo', 1), (6, 'Chaclacayo', 1), (7, 'Chorrillos', 1), (8, 'Cieneguilla', 1),
(9, 'Comas', 1), (10, 'El Agustino', 1), (11, 'Independencia', 1), (12, 'Jesús María', 1),
(13, 'La Molina', 1), (14, 'La Victoria', 1), (15, 'Lima', 1), (16, 'Lince', 1),
(17, 'Los Olivos', 1), (18, 'Lurigancho', 1), (19, 'Lurín', 1), (20, 'Magdalena del Mar', 1),
(21, 'Miraflores', 1), (22, 'Pachacámac', 1), (23, 'Pucusana', 1), (24, 'Pueblo Libre', 1),
(25, 'Puente Piedra', 1), (26, 'Punta Hermosa', 1), (27, 'Punta Negra', 1), (28, 'Rímac', 1),
(29, 'San Bartolo', 1), (30, 'San Borja', 1), (31, 'San Isidro', 1), (32, 'San Juan de Lurigancho', 1),
(33, 'San Juan de Miraflores', 1), (34, 'San Luis', 1), (35, 'San Martín de Porres', 1), (36, 'San Miguel', 1),
(37, 'Santa Anita', 1), (38, 'Santa María del Mar', 1), (39, 'Santa Rosa', 1), (40, 'Santiago de Surco', 1),
(41, 'Surquillo', 1), (42, 'Villa El Salvador', 1), (43, 'Villa María del Triunfo', 1), (44, 'Callao', 1),
(45, 'Bellavista', 1), (46, 'Carmen de La Legua-Reynoso', 1), (47, 'La Perla', 1), (48, 'La Punta', 1),
(49, 'Ventanilla', 1), (50, 'Mi Perú', 1);

-- 2. Alumnos con auth_user_id Vinculado (Demo vinculada a 018f0001-0000-7000-8000-000000000002)
INSERT IGNORE INTO students (
    id, student_code, auth_user_id, first_name, last_name_father, last_name_mother,
    birth_date, document_number, nationality, address, phone, mobile,
    email, status, district_id, gender_id, document_type_id, civil_status_id
) VALUES
('018f0001-0000-7000-9000-000000000002', 'ALU-2026-0001', '018f0001-0000-7000-8000-000000000002', 'Juan Carlos', 'Ramirez', 'Lopez', '2005-03-15', '78000001', 'Peruana', 'Av. Los Próceres 123 - San Juan de Lurigancho', '014500001', '900100001', 'estudiante1@universidad.edu.pe', 'ACTIVE', 32, 1, 1, 1),
('018f0001-0000-7000-9000-000000000012', 'ALU-2026-0002', '018f0001-0000-7000-8000-000000000012', 'Maria Fernanda', 'Torres', 'Diaz', '2004-07-22', '78000002', 'Peruana', 'Jr. Las Gardenias 456 - Jesús María', '014500002', '900100002', 'maria.torres@universidad.edu.pe', 'ACTIVE', 12, 2, 1, 1),
('018f0001-0000-7000-9000-000000000013', 'ALU-2026-0003', '018f0001-0000-7000-8000-000000000013', 'Luis Alberto', 'Mendoza', 'Rios', '2003-11-10', '78000003', 'Peruana', 'Av. Universitaria 789 - Los Olivos', '014500003', '900100003', 'luis.mendoza@universidad.edu.pe', 'ACTIVE', 17, 1, 1, 1);

-- 3. Docentes con auth_user_id Vinculado (Demo vinculada a 018f0001-0000-7000-8000-000000000003)
INSERT IGNORE INTO teachers (
    id, teacher_code, auth_user_id, first_name, last_name_father, last_name_mother,
    birth_date, document_number, nationality, address, phone, mobile,
    email, salary, status, district_id, gender_id, document_type_id, civil_status_id
) VALUES
('018f0001-0000-7000-9000-000000000003', 'DOC-2026-0001', '018f0001-0000-7000-8000-000000000003', 'Mario Antonio', 'Huapalla', 'Morales', '1980-02-10', '70000001', 'Peruana', 'Av. Universitaria 100', '014600001', '910200001', 'docente1@universidad.edu.pe', 4500.00, 'ACTIVE', 15, 1, 1, 2),
('018f0001-0000-7000-9000-000000000014', 'DOC-2026-0002', '018f0001-0000-7000-8000-000000000014', 'Patricia Elena', 'Salazar', 'Ramos', '1982-06-18', '70000002', 'Peruana', 'Av. Arequipa 1200', '014600002', '910200002', 'patricia.salazar@universidad.edu.pe', 4200.00, 'ACTIVE', 12, 2, 1, 2);

-- 4. Empleados Administrativos
INSERT IGNORE INTO employees (
    id, employee_code, auth_user_id, first_name, last_name_father, last_name_mother,
    birth_date, document_number, nationality, address, phone, mobile,
    email, salary, status, area_id, position_id, district_id, gender_id, document_type_id, civil_status_id
) VALUES
('018f0001-0000-7000-9000-000000000015', 'EMP-2026-0001', '018f0001-0000-7000-8000-000000000015', 'Roberto', 'Orue', 'Bustamante', '1975-05-10', '72000001', 'Peruana', 'Av. Arequipa 1201', '014700001', '920300001', 'roberto.orue@universidad.edu.pe', 5000.00, 'ACTIVE', 1, 1, 15, 1, 1, 2);
