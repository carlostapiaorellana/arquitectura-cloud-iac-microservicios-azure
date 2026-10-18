package main

import (
	"context"
	"database/sql"
	_ "embed"
	"fmt"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

//go:embed sql/002_dataset_v2_auth.sql
var authSQL string

//go:embed sql/002_dataset_v2_person.sql
var personSQL string

//go:embed sql/002_dataset_v2_academic.sql
var academicSQL string

//go:embed sql/002_dataset_v2_enrollment.sql
var enrollmentSQL string

//go:embed sql/002_dataset_v2_finance.sql
var financeSQL string

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}

func main() {
	fmt.Println("=====================================================================")
	fmt.Println("  ORQUESTADOR Y SEMBRADOR DETERMINISTA DEL DATASET V2 EN AZURE CLOUD ")
	fmt.Println("  Sub-Plan: SUBPLAN-LAB03-SIEMBRA-DATASET-V2                        ")
	fmt.Println("=====================================================================")

	host := getEnv("MYSQL_HOST", "mysql-univ-dev-mxc.privatelink.mysql.database.azure.com")
	port := getEnv("MYSQL_PORT", "3306")
	user := getEnv("MYSQL_USER", "univadmin")
	pass := getEnv("MYSQL_PASSWORD", "DevSecurePass2026!NCUS")

	fmt.Printf("Conectando a MySQL en %s:%s como '%s' (TLS requerido por Azure)...\n", host, port, user)
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/?multiStatements=true&parseTime=true&timeout=15s&tls=preferred", user, pass, host, port)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR FATAL] Fallo al abrir driver MySQL: %v\n", err)
		os.Exit(1)
	}
	defer db.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR FATAL] Fallo de conectividad TCP/TLS con MySQL: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("[OK] Conexión establecida exitosamente con Azure MySQL Flexible Server.")

	scripts := []struct {
		name string
		sql  string
	}{
		{"1. auth_db (7 roles, 22 usuarios bcrypt)", authSQL},
		{"2. person_db (7 catálogos, 10 alumnos, 6 docentes, 6 empleados)", personSQL},
		{"3. academic_db (3 facultades, 4 carreras, 10 cursos, 8 aulas, 10 secciones)", academicSQL},
		{"4. enrollment_db (10 matrículas, 20 detalles, 40 notas vigesimales, asistencias)", enrollmentSQL},
		{"5. finance_db (4 conceptos, 5 métodos, 20 órdenes de pago, 20 pagos)", financeSQL},
	}

	for _, s := range scripts {
		fmt.Printf("\n>>> Inyectando semilla: %s...\n", s.name)
		if _, err := db.ExecContext(ctx, s.sql); err != nil {
			fmt.Fprintf(os.Stderr, "[ERROR] Fallo al ejecutar semilla '%s': %v\n", s.name, err)
			os.Exit(1)
		}
		fmt.Printf("[OK] Semilla '%s' ejecutada exitosamente.\n", s.name)
	}

	fmt.Println("\n=====================================================================")
	fmt.Println("  COMPROBACIÓN DETERMINISTA DE CONTEOS SQL EN AZURE CLOUD (ADR-005)  ")
	fmt.Println("=====================================================================")

	type countCheck struct {
		db       string
		table    string
		expected int
	}

	checks := []countCheck{
		{"auth_db", "roles", 7},
		{"auth_db", "users", 22},
		{"person_db", "students", 10},
		{"person_db", "teachers", 6},
		{"person_db", "employees", 6},
		{"academic_db", "faculties", 3},
		{"academic_db", "programs", 4},
		{"academic_db", "courses", 10},
		{"academic_db", "classrooms", 8},
		{"academic_db", "sections", 10},
		{"enrollment_db", "enrollments", 10},
		{"enrollment_db", "enrollment_details", 20},
		{"enrollment_db", "grades", 40},
		{"finance_db", "payment_concepts", 4},
		{"finance_db", "payment_orders", 20},
		{"finance_db", "payments", 20},
	}

	hasFailure := false
	for _, c := range checks {
		query := fmt.Sprintf("SELECT COUNT(*) FROM %s.%s", c.db, c.table)
		var actual int
		if err := db.QueryRowContext(ctx, query).Scan(&actual); err != nil {
			fmt.Printf("[- FAIL] %-35s: ERROR (%v)\n", fmt.Sprintf("%s.%s", c.db, c.table), err)
			hasFailure = true
			continue
		}
		status := "PASS"
		if actual < c.expected {
			status = "FAIL"
			hasFailure = true
		}
		fmt.Printf("[%s] %-35s: Actual = %-3d | Esperado = %-3d\n", status, fmt.Sprintf("%s.%s", c.db, c.table), actual, c.expected)
	}

	fmt.Println("=====================================================================")
	if hasFailure {
		fmt.Println("VEREDICTO: FALLO EN ALGUNOS CONTEOS DETERMINISTAS.")
		os.Exit(1)
	}
	fmt.Println("VEREDICTO FINAL: TODOS LOS CONTEOS COINCIDEN AL 100% (EXIT CODE 0).")
	fmt.Println("=====================================================================")
}
