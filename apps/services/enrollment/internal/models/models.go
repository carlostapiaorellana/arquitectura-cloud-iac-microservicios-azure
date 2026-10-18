package models

import "time"

type EnrollmentStatus struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type EnrollmentType struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type GradeType struct {
	ID     int     `json:"id"`
	Name   string  `json:"name"`
	Weight float64 `json:"weight"`
}

type Enrollment struct {
	ID                 int                `json:"id"`
	StudentID          string             `json:"studentId"`
	AcademicPeriodID   int                `json:"academicPeriodId"`
	EnrollmentStatusID *int               `json:"enrollmentStatusId,omitempty"`
	EnrollmentTypeID   *int               `json:"enrollmentTypeId,omitempty"`
	Observations       *string            `json:"observations,omitempty"`
	CreatedAt          time.Time          `json:"createdAt"`
	Details            []EnrollmentDetail `json:"details,omitempty"`
}

type EnrollmentDetail struct {
	ID           int       `json:"id"`
	EnrollmentID int       `json:"enrollmentId"`
	SectionID    int       `json:"sectionId"`
	Status       string    `json:"status"`
	CreatedAt    time.Time `json:"createdAt"`
}

type Grade struct {
	ID                 int       `json:"id"`
	EnrollmentDetailID int       `json:"enrollmentDetailId"`
	SectionID          int       `json:"sectionId"`
	GradeTypeID        int       `json:"gradeTypeId"`
	GradeTypeName      string    `json:"gradeTypeName,omitempty"`
	Score              float64   `json:"score"`
	GradedAt           time.Time `json:"gradedAt"`
}

type AttendanceRecord struct {
	ID                 int       `json:"id"`
	EnrollmentDetailID int       `json:"enrollmentDetailId"`
	SessionDate        string    `json:"sessionDate"`
	IsPresent          bool      `json:"isPresent"`
	IsJustified        bool      `json:"isJustified"`
}

type RegisterEnrollmentRequest struct {
	AcademicPeriodID int    `json:"academicPeriodId"`
	EnrollmentTypeID int    `json:"enrollmentTypeId,omitempty"`
	SectionIDs       []int  `json:"sectionIds"`
	Observations     string `json:"observations,omitempty"`
}

type RegisterEnrollmentResponse struct {
	EnrollmentID   int    `json:"enrollmentId"`
	StudentID      string `json:"studentId"`
	Status         string `json:"status"`
	Message        string `json:"message"`
	EventPublished bool   `json:"eventPublished"`
}
