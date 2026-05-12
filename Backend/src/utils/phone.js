// ============================================================
// phone.js — minimal phone helpers (ESM)
// ============================================================

/**
 * Normalizes a phone number into digits-only form suitable for WhatsApp wa.me.
 * - Accepts values like "+92 300-1234567" or "923001234567".
 * - Returns "" for null/undefined/empty input.
 */
export function normalizeWhatsAppNumber(input) {
  if (input === undefined || input === null) return "";
  const raw = String(input).trim();
  if (!raw) return "";

  // Keep digits only; wa.me expects international number without '+'.
  const digits = raw.replace(/\D/g, "");
  return digits;
}

/**
 * Validates WhatsApp number in E.164-like digits-only form:
 * - 10 to 15 digits
 * - first digit 1-9 (no leading 0)
 */
export function isValidWhatsAppNumberDigits(digits) {
  if (digits === undefined || digits === null) return false;
  const v = String(digits).trim();
  return /^[1-9]\d{9,14}$/.test(v);
}
