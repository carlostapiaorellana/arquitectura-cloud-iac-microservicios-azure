package observability

import (
	"context"
	"crypto/rand"
	"net/http"
	"strings"
	"time"
)

type contextKey string

const (
	// HeaderCorrelationID cabecera estándar de correlación HTTP
	HeaderCorrelationID            = "X-Correlation-Id"
	ContextKeyCorrelation contextKey = "correlation_id"
	crockfordAlphabet              = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
)

// GenerateULID genera un identificador ordenable temporalmente de 26 caracteres Crockford Base32
// cumpliendo la especificación ULID (48 bits de timestamp en milisegundos + 80 bits de entropía criptográfica).
func GenerateULID() string {
	now := uint64(time.Now().UTC().UnixMilli())
	var timeBytes [6]byte
	timeBytes[0] = byte(now >> 40)
	timeBytes[1] = byte(now >> 32)
	timeBytes[2] = byte(now >> 24)
	timeBytes[3] = byte(now >> 16)
	timeBytes[4] = byte(now >> 8)
	timeBytes[5] = byte(now)

	var randomBytes [10]byte
	_, _ = rand.Read(randomBytes[:])

	var combined [16]byte
	copy(combined[0:6], timeBytes[:])
	copy(combined[6:16], randomBytes[:])

	var res [26]byte
	res[0] = crockfordAlphabet[(combined[0]&224)>>5]
	res[1] = crockfordAlphabet[combined[0]&31]
	res[2] = crockfordAlphabet[(combined[1]&248)>>3]
	res[3] = crockfordAlphabet[((combined[1]&7)<<2)|((combined[2]&192)>>6)]
	res[4] = crockfordAlphabet[(combined[2]&62)>>1]
	res[5] = crockfordAlphabet[((combined[2]&1)<<4)|((combined[3]&240)>>4)]
	res[6] = crockfordAlphabet[((combined[3]&15)<<1)|((combined[4]&128)>>7)]
	res[7] = crockfordAlphabet[(combined[4]&124)>>2]
	res[8] = crockfordAlphabet[((combined[4]&3)<<3)|((combined[5]&224)>>5)]
	res[9] = crockfordAlphabet[combined[5]&31]

	res[10] = crockfordAlphabet[(combined[6]&248)>>3]
	res[11] = crockfordAlphabet[((combined[6]&7)<<2)|((combined[7]&192)>>6)]
	res[12] = crockfordAlphabet[(combined[7]&62)>>1]
	res[13] = crockfordAlphabet[((combined[7]&1)<<4)|((combined[8]&240)>>4)]
	res[14] = crockfordAlphabet[((combined[8]&15)<<1)|((combined[9]&128)>>7)]
	res[15] = crockfordAlphabet[(combined[9]&124)>>2]
	res[16] = crockfordAlphabet[((combined[9]&3)<<3)|((combined[10]&224)>>5)]
	res[17] = crockfordAlphabet[combined[10]&31]

	res[18] = crockfordAlphabet[(combined[11]&248)>>3]
	res[19] = crockfordAlphabet[((combined[11]&7)<<2)|((combined[12]&192)>>6)]
	res[20] = crockfordAlphabet[(combined[12]&62)>>1]
	res[21] = crockfordAlphabet[((combined[12]&1)<<4)|((combined[13]&240)>>4)]
	res[22] = crockfordAlphabet[((combined[13]&15)<<1)|((combined[14]&128)>>7)]
	res[23] = crockfordAlphabet[(combined[14]&124)>>2]
	res[24] = crockfordAlphabet[((combined[14]&3)<<3)|((combined[15]&224)>>5)]
	res[25] = crockfordAlphabet[combined[15]&31]

	return string(res[:])
}

// GetCorrelationID obtiene el Correlation ID del contexto; si no existe, genera uno nuevo
func GetCorrelationID(ctx context.Context) string {
	if ctx == nil {
		return GenerateULID()
	}
	if val, ok := ctx.Value(ContextKeyCorrelation).(string); ok && val != "" {
		return val
	}
	return GenerateULID()
}

// WithCorrelationID adjunta un Correlation ID al contexto
func WithCorrelationID(ctx context.Context, correlationID string) context.Context {
	if correlationID == "" {
		correlationID = GenerateULID()
	}
	return context.WithValue(ctx, ContextKeyCorrelation, correlationID)
}

// ExtractOrGenerateCorrelationID extrae el Correlation ID de la petición HTTP o genera uno nuevo si no está presente
func ExtractOrGenerateCorrelationID(r *http.Request) string {
	if r == nil {
		return GenerateULID()
	}
	corrID := strings.TrimSpace(r.Header.Get(HeaderCorrelationID))
	if corrID != "" {
		return corrID
	}
	return GenerateULID()
}
