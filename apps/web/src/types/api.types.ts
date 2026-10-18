// ============================================================================
// Archivo: apps/web/src/types/api.types.ts
// Contratos Canónicos 1:1 con los 7 Microservicios Go (Lab 03 Sub-Fase D/E - REV-FE-01)
// ============================================================================

// ----------------------------------------------------------------------------
// 0. Sobre Canónico de Error (packages/error-handling/errors.go)
// ----------------------------------------------------------------------------
export type ErrorCode =
  | 'VALIDATION_ERROR'
  | 'BAD_REQUEST'
  | 'UNAUTHENTICATED'
  | 'FORBIDDEN'
  | 'RESOURCE_NOT_FOUND'
  | 'CONFLICT'
  | 'INTERNAL_ERROR'
  | 'SERVICE_UNAVAILABLE'
  | string;

export interface ApiErrorBody {
  code: ErrorCode;
  message: string;
  status: number;
  correlationId: string;
  timestamp: string; // RFC3339 e.g. "2026-10-16T19:20:00Z"
  details?: unknown;
}

export interface ApiErrorEnvelope {
  error: ApiErrorBody;
}

// Metadatos de respuesta capturados por el cliente HTTP (ej. cabeceras de caché y traza)
export type CacheStatus = 'HIT' | 'MISS' | 'BYPASS';

export interface ApiResponseMeta<T> {
  data: T;
  cacheStatus: CacheStatus;
  correlationId: string;
  latencyMs: number;
}

// ----------------------------------------------------------------------------
// 1. Identidad (auth-service :8081 -> /api/v1/auth/*)
// ----------------------------------------------------------------------------
export interface AuthLoginRequest {
  username: string;
  password: string;
}

// Alias para LoginRequest
export type LoginRequest = AuthLoginRequest;

export interface AuthLoginResponse {
  accessToken: string;
  tokenType: string;
  expiresIn: number; // Segundos (ej. 900 = 15 min)
  refreshToken?: string;
  userId: string;    // UUIDv7 ej. "018f0001-0000-7000-8000-000000000002"
  role: string;      // ej. "STUDENT"
  roles: string[];   // ej. ["STUDENT"]
  username: string;  // ej. "alu01"
}

// Alias para LoginResponse
export type LoginResponse = AuthLoginResponse;

export interface RefreshTokenRequest {
  refreshToken: string;
}

export interface RefreshTokenResponse {
  accessToken: string;
  tokenType: string;
  expiresIn: number;
  refreshToken?: string;
  userId: string;
  role: string;
  roles: string[];
  username: string;
}

// ----------------------------------------------------------------------------
// 2. Perfil del Alumno (person-service :8082 -> /api/v1/person/*)
// ----------------------------------------------------------------------------
export interface UserProfile {
  id: string;                // UUIDv7
  userType: string;          // 'STUDENT' | 'TEACHER' | 'EMPLOYEE' | 'ADMIN'
  institutionalCode: string; // ej. "ALU-2026-0001"
  authUserId: string;        // UUIDv7
  firstName: string;         // ej. "Juan Carlos"
  lastNameFather: string;    // ej. "Ramirez"
  lastNameMother: string;    // ej. "Lopez"
  fullName: string;          // ej. "Juan Carlos Ramirez Lopez"
  birthDate: string;         // YYYY-MM-DD
  documentNumber: string;    // DNI ej. "78000001"
  documentTypeName: string;
  nationality: string;
  address: string;
  phone?: string;
  mobile?: string;
  email: string;             // ej. "alu01@universidad.edu.pe"
  districtName: string;
  genderName: string;
  civilStatusName: string;
  status: string;            // 'ACTIVE' | 'INACTIVE' | 'SUSPENDED'
  updatedAt: string;         // ISO-8601
}

export interface UpdateContactRequest {
  address: string;
  phone?: string;
  mobile?: string;
}

// ----------------------------------------------------------------------------
// 3. Gestión Académica (academic-service :8083 -> /api/v1/academic/*)
// ----------------------------------------------------------------------------
export interface Program {
  id: number;
  facultyId: number;
  code: string;      // ej. "ING-SIS"
  name: string;      // ej. "Ingeniería de Sistemas"
  degree: string;    // ej. "Bachiller en Ingeniería de Sistemas"
  createdAt: string;
}

export interface Course {
  id: number;
  programId: number;
  sercur: string;    // Código serie del curso, ej. "SIS-101"
  nomcur: string;    // Nombre de la asignatura, ej. "Algoritmos y Estructura de Datos"
  crecur: number;    // Créditos académicos, ej. 4
  blocur?: string;   // Bloque / Ciclo curricular, ej. "CICLO-I"
  createdAt: string;
}

export interface Section {
  id: number;
  courseId: number;
  academicPeriodId: number;
  code: string;             // ej. "SEC-A"
  teacherId?: string;
  capacity: number;
  enrolled: number;
  createdAt: string;
}

// ----------------------------------------------------------------------------
// 4. Matrículas y Notas (enrollment-service :8084 -> /api/v1/enrollment/*)
// ----------------------------------------------------------------------------
export interface EnrollmentDetail {
  id: number;
  enrollmentId: number;
  sectionId: number;
  status: string;
  createdAt: string;
}

export interface Enrollment {
  id: number;
  studentId: string;
  academicPeriodId: number;
  enrollmentStatusId?: number;
  enrollmentTypeId?: number;
  observations?: string;
  createdAt: string;
  details?: EnrollmentDetail[];
}

export interface Grade {
  id: number;
  enrollmentDetailId: number;
  sectionId: number;
  gradeTypeId: number;
  gradeTypeName?: string;
  score: number; // Escala vigesimal: 0.00 a 20.00
  gradedAt: string;
}

export interface RegisterEnrollmentRequest {
  academicPeriodId: number;
  enrollmentTypeId?: number;
  sectionIds: number[];
  observations?: string;
}

// ----------------------------------------------------------------------------
// 5. Tesorería y Pagos (finance-service :8085 -> /api/v1/finance/*)
// ----------------------------------------------------------------------------
export interface PaymentOrder {
  id: number;
  studentId: string;
  enrollmentId?: number;
  conceptId: number;
  conceptCode?: string;
  conceptName?: string;
  statusId: number;
  statusCode?: string;
  statusName?: string;
  amount: number;
  dueDate?: string;
  createdAt: string;
}

export interface ProcessPaymentRequest {
  paymentOrderId: number;
  methodCode: 'CARD' | 'TRANSFER' | 'COUNTER' | 'WALLET' | string;
  amount: number;
}

export interface PaymentResponse {
  paymentId: number;
  paymentOrderId: number;
  amount: number;
  transactionRef: string;
  idempotencyKey: string;
  status: string;
  paidAt: string;
}

// ----------------------------------------------------------------------------
// 6. Biblioteca Virtual NoSQL (library-service :8086 -> /api/v1/library/*)
// ----------------------------------------------------------------------------
export interface Book {
  id: string;
  partitionKey: string;
  isbn: string;
  title: string;
  author: string;
  category: string;
  availableCopies: number;
  totalCopies: number;
}

export interface Loan {
  id: string;
  partitionKey: string;
  studentId: string;
  bookId: string;
  bookTitle: string;
  loanDate: string;
  dueDate: string;
  status: 'ACTIVE' | 'RETURNED' | 'OVERDUE';
}

export interface CreateLoanRequest {
  bookId: string;
}

// ----------------------------------------------------------------------------
// 7. Aula Virtual LMS NoSQL (lms-service :8087 -> /api/v1/lms/*)
// ----------------------------------------------------------------------------
export interface LmsEvaluation {
  evaluationId: string;
  title: string;
  type: 'PRAC' | 'EXAM' | 'LAB' | 'PROJ' | string;
  weight: number;
  dueDate: string;
}

export interface StudentCourseView {
  enrollmentId: string;
  courseId: string;
  sectionId: string;
  courseCode: string;
  title: string;
  role: string;
  progressPercentage: number;
  syllabusUrl?: string;
  evaluations?: LmsEvaluation[];
}
