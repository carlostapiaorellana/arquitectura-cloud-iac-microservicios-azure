package models

type LmsEvaluation struct {
	EvaluationID string `json:"evaluationId"`
	Title        string `json:"title"`
	Type         string `json:"type"` // "PRAC", "EXAM", "LAB", "PROJ"
	Weight       int    `json:"weight"`
	DueDate      string `json:"dueDate"`
}

type LmsCourse struct {
	ID          string          `json:"id"`
	PartitionKey string         `json:"partitionKey"`
	SectionID   string          `json:"sectionId"`
	CourseCode  string          `json:"courseCode"`
	Title       string          `json:"title"`
	SyllabusURL string          `json:"syllabusUrl"`
	Evaluations []LmsEvaluation `json:"evaluations"`
}

type LmsEnrollment struct {
	ID                 string  `json:"id"`
	PartitionKey       string  `json:"partitionKey"`
	StudentID          string  `json:"studentId"`
	CourseID           string  `json:"courseId"`
	SectionID          string  `json:"sectionId"`
	CourseCode         string  `json:"courseCode"`
	Title              string  `json:"title"`
	Role               string  `json:"role"` // "STUDENT", "TEACHER"
	ProgressPercentage float64 `json:"progressPercentage"`
}

type StudentCourseView struct {
	EnrollmentID       string          `json:"enrollmentId"`
	CourseID           string          `json:"courseId"`
	SectionID          string          `json:"sectionId"`
	CourseCode         string          `json:"courseCode"`
	Title              string          `json:"title"`
	Role               string          `json:"role"`
	ProgressPercentage float64         `json:"progressPercentage"`
	SyllabusURL        string          `json:"syllabusUrl,omitempty"`
	Evaluations        []LmsEvaluation `json:"evaluations,omitempty"`
}
