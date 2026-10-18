package models

import "time"

type PaymentConcept struct {
	ID        int       `json:"id"`
	Code      string    `json:"code"`
	Name      string    `json:"name"`
	Amount    float64   `json:"amount"`
	CreatedAt time.Time `json:"createdAt"`
}

type PaymentMethod struct {
	ID        int       `json:"id"`
	Code      string    `json:"code"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"createdAt"`
}

type PaymentStatus struct {
	ID        int       `json:"id"`
	Code      string    `json:"code"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"createdAt"`
}

type PaymentOrder struct {
	ID           int        `json:"id"`
	StudentID    string     `json:"studentId"`
	EnrollmentID *int       `json:"enrollmentId,omitempty"`
	ConceptID    int        `json:"conceptId"`
	ConceptCode  string     `json:"conceptCode,omitempty"`
	ConceptName  string     `json:"conceptName,omitempty"`
	StatusID     int        `json:"statusId"`
	StatusCode   string     `json:"statusCode,omitempty"`
	StatusName   string     `json:"statusName,omitempty"`
	Amount       float64    `json:"amount"`
	DueDate      *string    `json:"dueDate,omitempty"`
	CreatedAt    time.Time  `json:"createdAt"`
}

type Payment struct {
	ID             int       `json:"id"`
	PaymentOrderID int       `json:"paymentOrderId"`
	MethodID       int       `json:"methodId"`
	Amount         float64   `json:"amount"`
	TransactionRef string    `json:"transactionRef"`
	IdempotencyKey string    `json:"idempotencyKey"`
	PaidAt         time.Time `json:"paidAt"`
}

type ProcessPaymentRequest struct {
	PaymentOrderID int     `json:"paymentOrderId"`
	MethodCode     string  `json:"methodCode"`
	Amount         float64 `json:"amount"`
}

type PaymentResponse struct {
	PaymentID      int       `json:"paymentId"`
	PaymentOrderID int       `json:"paymentOrderId"`
	Amount         float64   `json:"amount"`
	TransactionRef string    `json:"transactionRef"`
	IdempotencyKey string    `json:"idempotencyKey"`
	Status         string    `json:"status"`
	PaidAt         time.Time `json:"paidAt"`
}
