package models

import "time"

type Faculty struct {
	ID        int       `json:"id"`
	Code      string    `json:"code"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"createdAt"`
}

type Program struct {
	ID        int       `json:"id"`
	FacultyID int       `json:"facultyId"`
	Code      string    `json:"code"`
	Name      string    `json:"name"`
	Degree    string    `json:"degree"`
	CreatedAt time.Time `json:"createdAt"`
}

type StudyPlan struct {
	ID        int       `json:"id"`
	ProgramID int       `json:"programId"`
	Code      string    `json:"code"`
	Name      string    `json:"name"`
	Year      int       `json:"year"`
	IsActive  bool      `json:"isActive"`
	CreatedAt time.Time `json:"createdAt"`
}

type Course struct {
	ID        int       `json:"id"`
	ProgramID int       `json:"programId"`
	Sercur    string    `json:"sercur"`
	Nomcur    string    `json:"nomcur"`
	Crecur    int       `json:"crecur"`
	Blocur    string    `json:"blocur,omitempty"`
	CreatedAt time.Time `json:"createdAt"`
}

type Classroom struct {
	ID              int       `json:"id"`
	ClassroomTypeID int       `json:"classroomTypeId"`
	LocationID      int       `json:"locationId"`
	StatusID        int       `json:"statusId"`
	Code            string    `json:"code"`
	Capacity        int       `json:"capacity"`
	CreatedAt       time.Time `json:"createdAt"`
}

type Section struct {
	ID               int       `json:"id"`
	CourseID         int       `json:"courseId"`
	AcademicPeriodID int       `json:"academicPeriodId"`
	Code             string    `json:"code"`
	TeacherID        *string   `json:"teacherId,omitempty"`
	Capacity         int       `json:"capacity"`
	Enrolled         int       `json:"enrolled"`
	CreatedAt        time.Time `json:"createdAt"`
}

type Schedule struct {
	ID          int       `json:"id"`
	SectionID   int       `json:"sectionId"`
	BlockID     int       `json:"blockId"`
	WeekdayID   int       `json:"weekdayId"`
	ClassroomID int       `json:"classroomId"`
	CreatedAt   time.Time `json:"createdAt"`
}
