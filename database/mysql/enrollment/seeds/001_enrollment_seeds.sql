-- ============================================================
-- SEEDS: Datos Semilla Idempotentes para enrollment_db
-- Contexto Delimitado: Matrículas, Evaluaciones y Asistencia
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

USE enrollment_db;

-- 1. Catálogos de Matrícula y Evaluación
INSERT IGNORE INTO enrollment_statuses (id, name) VALUES
(1, 'RESERVED'),
(2, 'ENROLLED'),
(3, 'CANCELLED'),
(4, 'COMPLETED');

INSERT IGNORE INTO enrollment_types (id, name) VALUES
(1, 'REGULAR'),
(2, 'EXTEMPORANEA'),
(3, 'DIRIGIDA');

INSERT IGNORE INTO grade_types (id, name, weight) VALUES
(1, 'Examen Parcial', 0.30),
(2, 'Examen Final', 0.40),
(3, 'Práctica Calificada 1', 0.15),
(4, 'Práctica Calificada 2', 0.15);

-- 2. Matrícula Demo para Estudiante alu01 (auth_user_id = 018f0001-0000-7000-8000-000000000002)
INSERT IGNORE INTO enrollments (
    id, student_id, academic_period_id, enrollment_status_id, enrollment_type_id, observations, created_at
) VALUES
(1, '018f0001-0000-7000-8000-000000000002', 1, 2, 1, 'Matrícula regular periodo 2026-I', '2026-03-01 09:00:00'),
(2, '018f0001-0000-7000-9000-000000000002', 1, 2, 1, 'Matrícula alias secundaria 2026-I', '2026-03-01 09:00:00');

-- 3. Detalle de Secciones Matriculadas
INSERT IGNORE INTO enrollment_details (
    id, enrollment_id, section_id, status, created_at
) VALUES
(1, 1, 1, 'ENROLLED', '2026-03-01 09:05:00'),
(2, 1, 2, 'ENROLLED', '2026-03-01 09:05:00'),
(3, 2, 1, 'ENROLLED', '2026-03-01 09:05:00'),
(4, 2, 2, 'ENROLLED', '2026-03-01 09:05:00');

-- 4. Calificaciones Registradas para el Alumno
INSERT IGNORE INTO grades (
    id, enrollment_detail_id, grade_type_id, score, graded_at
) VALUES
(1, 1, 1, 16.50, '2026-05-15 10:00:00'),
(2, 1, 3, 18.00, '2026-04-10 10:00:00'),
(3, 2, 1, 17.00, '2026-05-16 11:00:00'),
(4, 3, 1, 16.50, '2026-05-15 10:00:00'),
(5, 4, 1, 17.00, '2026-05-16 11:00:00');

-- 5. Registro de Asistencias
INSERT IGNORE INTO attendance (
    id, enrollment_detail_id, session_date, is_present, is_justified
) VALUES
(1, 1, '2026-03-10', 1, 0),
(2, 1, '2026-03-17', 1, 0),
(3, 1, '2026-03-24', 1, 0);

-- 6. Historial de Traslados
INSERT IGNORE INTO transfers (
    id, student_id, source_program_id, target_program_id, academic_period_id, status, created_at
) VALUES
(1, '018f0001-0000-7000-8000-000000000002', 2, 1, 1, 'APPROVED', '2026-02-15 10:00:00');
