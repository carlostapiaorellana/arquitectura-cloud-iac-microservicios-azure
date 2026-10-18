package models

type Book struct {
	ID              string `json:"id"`
	PartitionKey    string `json:"partitionKey"`
	ISBN            string `json:"isbn"`
	Title           string `json:"title"`
	Author          string `json:"author"`
	Category        string `json:"category"`
	AvailableCopies int    `json:"availableCopies"`
	TotalCopies     int    `json:"totalCopies"`
}

type Loan struct {
	ID           string `json:"id"`
	PartitionKey string `json:"partitionKey"`
	StudentID    string `json:"studentId"`
	BookID       string `json:"bookId"`
	BookTitle    string `json:"bookTitle"`
	LoanDate     string `json:"loanDate"`
	DueDate      string `json:"dueDate"`
	Status       string `json:"status"` // "ACTIVE", "RETURNED", "OVERDUE"
}

type CreateLoanRequest struct {
	BookID string `json:"bookId"`
}
