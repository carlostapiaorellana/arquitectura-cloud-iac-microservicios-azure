-- ============================================================
-- BOOTSTRAP: Inicialización de Bases de Datos y Usuarios Segregados
-- Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
-- ============================================================

-- 1. Creación de Bases de Datos Lógicas Independientes
CREATE DATABASE IF NOT EXISTS auth_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS person_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS academic_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS enrollment_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS finance_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 2. Creación de Usuarios de Migración DDL (ALL PRIVILEGES en su BD)
CREATE USER IF NOT EXISTS 'auth_migrator'@'%' IDENTIFIED BY 'auth_migrator_pass123';
GRANT ALL PRIVILEGES ON auth_db.* TO 'auth_migrator'@'%';

CREATE USER IF NOT EXISTS 'person_migrator'@'%' IDENTIFIED BY 'person_migrator_pass123';
GRANT ALL PRIVILEGES ON person_db.* TO 'person_migrator'@'%';

CREATE USER IF NOT EXISTS 'academic_migrator'@'%' IDENTIFIED BY 'academic_migrator_pass123';
GRANT ALL PRIVILEGES ON academic_db.* TO 'academic_migrator'@'%';

CREATE USER IF NOT EXISTS 'enrollment_migrator'@'%' IDENTIFIED BY 'enrollment_migrator_pass123';
GRANT ALL PRIVILEGES ON enrollment_db.* TO 'enrollment_migrator'@'%';

CREATE USER IF NOT EXISTS 'finance_migrator'@'%' IDENTIFIED BY 'finance_migrator_pass123';
GRANT ALL PRIVILEGES ON finance_db.* TO 'finance_migrator'@'%';

-- 3. Creación de Usuarios de Aplicación Runtime DML (Mínimo Privilegio)
CREATE USER IF NOT EXISTS 'auth_user'@'%' IDENTIFIED BY 'auth_user_pass123';
GRANT SELECT, INSERT, UPDATE, DELETE ON auth_db.* TO 'auth_user'@'%';

CREATE USER IF NOT EXISTS 'person_user'@'%' IDENTIFIED BY 'person_user_pass123';
GRANT SELECT, INSERT, UPDATE, DELETE ON person_db.* TO 'person_user'@'%';

CREATE USER IF NOT EXISTS 'academic_user'@'%' IDENTIFIED BY 'academic_user_pass123';
GRANT SELECT, INSERT, UPDATE, DELETE ON academic_db.* TO 'academic_user'@'%';

CREATE USER IF NOT EXISTS 'enrollment_user'@'%' IDENTIFIED BY 'enrollment_user_pass123';
GRANT SELECT, INSERT, UPDATE, DELETE ON enrollment_db.* TO 'enrollment_user'@'%';

CREATE USER IF NOT EXISTS 'finance_user'@'%' IDENTIFIED BY 'finance_user_pass123';
GRANT SELECT, INSERT, UPDATE, DELETE ON finance_db.* TO 'finance_user'@'%';

FLUSH PRIVILEGES;
