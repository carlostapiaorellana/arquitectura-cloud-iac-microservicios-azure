package apicontracts

import "time"

// Constantes de tipos de eventos institucionales para el Event Bus
const (
	EventTypeStudentCreated      = "student.created"
	EventTypeEnrollmentConfirmed = "enrollment.confirmed"
	EventTypePaymentCompleted    = "payment.completed"
	EventTypeUserCreated         = "user.created"

	// Tópicos y colas canónicas
	TopicStudentEvents      = "student.events"
	TopicEnrollmentEvents   = "enrollment.events"
	TopicAuthEvents         = "auth.events"
	QueuePaymentsProcessing = "payments.processing"
)

// BaseEvent define los atributos canónicos comunes para toda la mensajería EDA
type BaseEvent struct {
	EventID       string `json:"eventId"`
	EventType     string `json:"eventType"`
	CorrelationID string `json:"correlationId"`
	Timestamp     string `json:"timestamp"`
}

// StudentCreatedPayload contiene los datos del nuevo estudiante registrado
type StudentCreatedPayload struct {
	StudentID      string `json:"studentId"`
	StudentCode    string `json:"studentCode"`
	DocumentNumber string `json:"documentNumber"`
	Email          string `json:"email"`
	FirstName      string `json:"firstName"`
	LastName       string `json:"lastName"`
	FacultyID      int    `json:"facultyId"`
	CareerID       int    `json:"careerId"`
	AdmissionDate  string `json:"admissionDate"`
}

// StudentCreatedEvent contrato emitido por person-service hacia student.events
type StudentCreatedEvent struct {
	BaseEvent
	Payload StudentCreatedPayload `json:"payload"`
}

// EnrollmentConfirmedPayload contiene los datos de la matrícula confirmada
type EnrollmentConfirmedPayload struct {
	EnrollmentID   string   `json:"enrollmentId"`
	StudentID      string   `json:"studentId"`
	AcademicTermID int      `json:"academicTermId"`
	StudyPlanID    int      `json:"studyPlanId"`
	SectionIDs     []int    `json:"sectionIds"`
	TotalCredits   int      `json:"totalCredits"`
	TuitionAmount  float64  `json:"tuitionAmount"`
	Currency       string   `json:"currency"`
}

// EnrollmentConfirmedEvent contrato emitido por enrollment-service hacia enrollment.events
type EnrollmentConfirmedEvent struct {
	BaseEvent
	Payload EnrollmentConfirmedPayload `json:"payload"`
}

// PaymentCompletedPayload contiene los datos de un pago transaccional procesado
type PaymentCompletedPayload struct {
	PaymentID      string  `json:"paymentId"`
	PaymentOrderID string  `json:"paymentOrderId"`
	EnrollmentID   string  `json:"enrollmentId"`
	StudentID      string  `json:"studentId"`
	Amount         float64 `json:"amount"`
	Currency       string  `json:"currency"`
	PaymentMethod  string  `json:"paymentMethod"`
	TransactionRef string  `json:"transactionRef"`
	PaidAt         string  `json:"paidAt"`
}

// PaymentCompletedEvent contrato procesado a través de payments.processing
type PaymentCompletedEvent struct {
	BaseEvent
	Payload PaymentCompletedPayload `json:"payload"`
}

// UserCreatedPayload contiene los datos del usuario creado
type UserCreatedPayload struct {
	UserID   string `json:"userId"`
	Username string `json:"username"`
	Email    string `json:"email"`
	Role     string `json:"role"`
}

// UserCreatedEvent contrato emitido por auth-service hacia auth.events
type UserCreatedEvent struct {
	BaseEvent
	Payload UserCreatedPayload `json:"payload"`
}

// NewBaseEvent genera la base de un evento con timestamp UTC en formato RFC3339
func NewBaseEvent(eventID, eventType, correlationID string) BaseEvent {
	return BaseEvent{
		EventID:       eventID,
		EventType:     eventType,
		CorrelationID: correlationID,
		Timestamp:     time.Now().UTC().Format(time.RFC3339),
	}
}
