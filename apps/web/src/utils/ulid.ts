// ============================================================================
// Generador ligero de ULID (Universally Unique Lexicographically Sortable Identifier)
// Base32 Crockford: 26 caracteres (10 tiempo + 16 aleatorios)
// ============================================================================

const ENCODING = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const ENCODING_LEN = ENCODING.length;

let lastTime = 0;
let lastRandom: number[] = new Array(16).fill(0);

export function generateULID(now: number = Date.now()): string {
  // Manejo de monotonicidad en el mismo milisegundo
  if (now === lastTime) {
    // Incrementar los bytes aleatorios
    for (let i = lastRandom.length - 1; i >= 0; i--) {
      if (lastRandom[i] < ENCODING_LEN - 1) {
        lastRandom[i]++;
        break;
      } else {
        lastRandom[i] = 0;
      }
    }
  } else {
    lastTime = now;
    if (typeof crypto !== 'undefined' && crypto.getRandomValues) {
      const buffer = new Uint8Array(16);
      crypto.getRandomValues(buffer);
      for (let i = 0; i < 16; i++) {
        lastRandom[i] = buffer[i] % ENCODING_LEN;
      }
    } else {
      for (let i = 0; i < 16; i++) {
        lastRandom[i] = Math.floor(Math.random() * ENCODING_LEN);
      }
    }
  }

  // Componente de tiempo (10 caracteres)
  let timeStr = '';
  let timeVal = now;
  for (let i = 9; i >= 0; i--) {
    const mod = timeVal % ENCODING_LEN;
    timeStr = ENCODING.charAt(mod) + timeStr;
    timeVal = Math.floor(timeVal / ENCODING_LEN);
  }

  // Componente aleatorio (16 caracteres)
  let randStr = '';
  for (let i = 0; i < 16; i++) {
    randStr += ENCODING.charAt(lastRandom[i]);
  }

  return timeStr + randStr;
}
