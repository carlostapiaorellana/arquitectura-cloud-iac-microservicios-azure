package nosql

import (
	"context"
	"errors"
)

var (
	// ErrNotFound se retorna cuando un documento no existe en la colección
	ErrNotFound = errors.New("documento no encontrado en el almacén nosql")
	// ErrInvalidInput se retorna ante argumentos nulos o inválidos
	ErrInvalidInput = errors.New("parámetros de documento o colección inválidos")
	// ErrUnsupportedProvider se retorna cuando el proveedor configurado no es reconocido
	ErrUnsupportedProvider = errors.New("proveedor nosql no soportado")
)

// DocumentStore define el contrato agnóstico para persistencia documental NoSQL
// compatible con Azure Cosmos DB y emulación local (DynamoDB Local o Motor en Memoria).
type DocumentStore interface {
	// PutItem guarda o reemplaza un documento en la colección especificada
	PutItem(ctx context.Context, collection string, partitionKey string, item any) error

	// GetItem recupera un documento por su clave de partición e identificador
	GetItem(ctx context.Context, collection string, partitionKey string, id string, dest any) error

	// QueryByPartition obtiene todos los documentos que pertenecen a una clave de partición
	QueryByPartition(ctx context.Context, collection string, partitionKey string, dest any) error

	// DeleteItem elimina un documento por su clave de partición e identificador
	DeleteItem(ctx context.Context, collection string, partitionKey string, id string) error

	// UpdateAtomicCounter incrementa o decrementa atómicamente un contador numérico en un documento
	UpdateAtomicCounter(ctx context.Context, collection string, partitionKey string, id string, counterField string, delta int64) (int64, error)

	// Ping comprueba la conectividad activa contra el motor NoSQL
	Ping(ctx context.Context) error

	// Close libera recursos y conexiones activas
	Close() error
}

// Config estructura de configuración para inicializar un DocumentStore
type Config struct {
	Provider           string // "cosmos", "dynamodb_local" o "memory"
	Endpoint           string // URL base del servicio
	Key                string // Clave de acceso o secret
	DatabaseName       string // Nombre de la base lógica
	UseManagedIdentity bool   // Habilita autenticación vía Azure Managed Identity
	Region             string // Región de Azure o AWS local
}

// NewDocumentStore crea el adaptador correspondiente según la configuración
func NewDocumentStore(cfg Config) (DocumentStore, error) {
	switch cfg.Provider {
	case "cosmos", "azure_cosmos":
		return NewCosmosAdapter(cfg)
	case "dynamodb_local", "dynamodb", "local":
		return NewDynamoDBLocalAdapter(cfg)
	case "memory", "inmemory":
		return NewMemoryAdapter(), nil
	default:
		// Detección automática por Endpoint
		if cfg.Endpoint != "" && (contains(cfg.Endpoint, "documents.azure.com") || contains(cfg.Endpoint, "cosmos")) {
			return NewCosmosAdapter(cfg)
		}
		if cfg.Endpoint != "" && contains(cfg.Endpoint, "8000") {
			return NewDynamoDBLocalAdapter(cfg)
		}
		// Fallback local seguro por defecto para $0.00
		return NewDynamoDBLocalAdapter(cfg)
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || (len(s) > len(substr) && searchString(s, substr)))
}

func searchString(s, substr string) bool {
	for i := 0; i+len(substr) <= len(s); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
