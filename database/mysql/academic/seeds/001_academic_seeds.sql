-- ============================================================
-- SEEDS: Datos Semilla Idempotentes para academic_db
-- Contexto Delimitado: Catálogos Académicos, Cursos, Aulas, Secciones y Horarios
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE academic_db;

-- 1. Facultades y Periodos Académicos
INSERT IGNORE INTO faculties (id, code, name) VALUES
(1, 'FIA', 'Facultad de Ingeniería y Arquitectura'),
(2, 'FCE', 'Facultad de Ciencias Económicas y Empresariales');

INSERT IGNORE INTO academic_periods (id, name, start_date, end_date, is_active) VALUES
(1, '2026-I', '2026-03-01', '2026-07-31', 1),
(2, '2026-II', '2026-08-15', '2026-12-20', 0);

-- 2. Bloques Horarios y Días de la Semana
INSERT IGNORE INTO blocks (id, name, start_time, end_time) VALUES
(1, 'Bloque M1 (08:00 - 10:00)', '08:00:00', '10:00:00'),
(2, 'Bloque M2 (10:00 - 12:00)', '10:00:00', '12:00:00'),
(3, 'Bloque T1 (14:00 - 16:00)', '14:00:00', '16:00:00'),
(4, 'Bloque N1 (18:00 - 20:00)', '18:00:00', '20:00:00');

INSERT IGNORE INTO weekdays (id, name, short_name) VALUES
(1, 'Lunes', 'LUN'),
(2, 'Martes', 'MAR'),
(3, 'Miércoles', 'MIE'),
(4, 'Jueves', 'JUE'),
(5, 'Viernes', 'VIE'),
(6, 'Sábado', 'SAB');

-- 3. Ambientes Físicos (Tipos, Ubicaciones y Estados)
INSERT IGNORE INTO classroom_types (id, name) VALUES
(1, 'Aula Teórica'),
(2, 'Laboratorio de Cómputo'),
(3, 'Auditorio');

INSERT IGNORE INTO locations (id, name, address) VALUES
(1, 'Pabellón A - Piso 1', 'Campus Central - Av. Universitaria 100'),
(2, 'Pabellón B - Piso 2', 'Campus Central - Av. Universitaria 100');

INSERT IGNORE INTO classroom_statuses (id, name) VALUES
(1, 'Disponible'),
(2, 'En Mantenimiento'),
(3, 'Fuera de Servicio');

-- 4. Programas Profesionales y Planes de Estudio
INSERT IGNORE INTO programs (id, faculty_id, code, name, degree) VALUES
(1, 1, 'ING-SIS', 'Ingeniería de Sistemas', 'Bachiller en Ingeniería de Sistemas'),
(2, 1, 'ING-IND', 'Ingeniería Industrial', 'Bachiller en Ingeniería Industrial'),
(3, 2, 'ADM-EMP', 'Administración de Empresas', 'Bachiller en Administración de Empresas');

INSERT IGNORE INTO study_plans (id, program_id, code, name, year, is_active) VALUES
(1, 1, 'PLAN-SIS-2026', 'Plan Curricular de Ingeniería de Sistemas 2026', 2026, 1),
(2, 2, 'PLAN-IND-2026', 'Plan Curricular de Ingeniería Industrial 2026', 2026, 1);

-- 5. Cursos Ofertados
INSERT IGNORE INTO courses (id, program_id, sercur, nomcur, crecur, blocur) VALUES
(1, 1, 'SIS-101', 'Algoritmos y Estructura de Datos', 4, 'B1'),
(2, 1, 'SIS-102', 'Bases de Datos Relacionales y NoSQL', 4, 'B1'),
(3, 1, 'SIS-103', 'Arquitectura de Software y Cloud Computing', 5, 'B2'),
(4, 1, 'SIS-104', 'Sistemas Distribuidos y Microservicios', 5, 'B2'),
(5, 2, 'IND-101', 'Investigación de Operaciones', 4, 'B1');

-- 6. Aulas Asignadas
INSERT IGNORE INTO classrooms (id, classroom_type_id, location_id, status_id, code, capacity) VALUES
(1, 1, 1, 1, 'AULA-101', 40),
(2, 2, 1, 1, 'LAB-102', 30),
(3, 1, 2, 1, 'AULA-201', 45);

-- 7. Secciones Abiertas (teacher_id desnormalizado hacia person_db)
INSERT IGNORE INTO sections (id, course_id, academic_period_id, code, teacher_id, capacity, enrolled) VALUES
(1, 1, 1, 'SEC-01', '018f0001-0000-7000-9000-000000000003', 40, 1),
(2, 2, 1, 'SEC-01', '018f0001-0000-7000-9000-000000000003', 40, 1),
(3, 3, 1, 'SEC-01', '018f0001-0000-7000-9000-000000000014', 35, 0);

-- 8. Horarios
INSERT IGNORE INTO schedules (id, section_id, block_id, weekday_id, classroom_id) VALUES
(1, 1, 1, 1, 2),
(2, 2, 2, 3, 2),
(3, 3, 4, 5, 1);
