package models

import "time"

// UserProfile perfil canónico unificado devuelto por /api/v1/person/profile/me
type UserProfile struct {
	ID               string    `json:"id"`
	UserType         string    `json:"userType"` // "STUDENT", "TEACHER", "EMPLOYEE"
	InstitutionalCode string    `json:"institutionalCode"`
	AuthUserID       string    `json:"authUserId"`
	FirstName        string    `json:"firstName"`
	LastNameFather   string    `json:"lastNameFather"`
	LastNameMother   string    `json:"lastNameMother"`
	FullName         string    `json:"fullName"`
	BirthDate        string    `json:"birthDate"`
	DocumentNumber   string    `json:"documentNumber"`
	DocumentTypeName string    `json:"documentTypeName"`
	Nationality      string    `json:"nationality"`
	Address          string    `json:"address"`
	Phone            string    `json:"phone,omitempty"`
	Mobile           string    `json:"mobile,omitempty"`
	Email            string    `json:"email"`
	DistrictName     string    `json:"districtName"`
	GenderName       string    `json:"genderName"`
	CivilStatusName  string    `json:"civilStatusName"`
	Status           string    `json:"status"`
	Salary           *float64  `json:"salary,omitempty"`
	UpdatedAt        time.Time `json:"updatedAt"`
}

// UpdateContactRequest DTO para actualización de datos de contacto
type UpdateContactRequest struct {
	Address string `json:"address"`
	Phone   string `json:"phone,omitempty"`
	Mobile  string `json:"mobile,omitempty"`
}

// Student entidad de persistencia en person_db
type Student struct {
	ID             string    `json:"id"`
	StudentCode    string    `json:"studentCode"`
	AuthUserID     string    `json:"authUserId"`
	FirstName      string    `json:"firstName"`
	LastNameFather string    `json:"lastNameFather"`
	LastNameMother string    `json:"lastNameMother"`
	BirthDate      string    `json:"birthDate"`
	DocumentNumber string    `json:"documentNumber"`
	Nationality    string    `json:"nationality"`
	Address        string    `json:"address"`
	Phone          string    `json:"phone,omitempty"`
	Mobile         string    `json:"mobile,omitempty"`
	Email          string    `json:"email"`
	Status         string    `json:"status"`
	DistrictID     int       `json:"districtId"`
	GenderID       int       `json:"genderId"`
	DocumentTypeID int       `json:"documentTypeId"`
	CivilStatusID  int       `json:"civilStatusId"`
	CreatedAt      time.Time `json:"createdAt"`
	UpdatedAt      time.Time `json:"updatedAt"`
}

// CatalogItem elemento genérico de catálogos demográficos
type CatalogItem struct {
	ID     int    `json:"id"`
	Nombre string `json:"nombre"`
	Estado bool   `json:"estado"`
}
