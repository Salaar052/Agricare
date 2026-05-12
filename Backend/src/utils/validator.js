// ============================================================
// validator.js — Request Input Validation (ESM)
// ============================================================

const VALID_SPACES = ['balcony', 'garden', 'indoor'];
const VALID_SUNLIGHT = ['full', 'partial', 'shade'];
const VALID_WATER = ['low', 'medium', 'high'];

/**
 * Validates the /recommend-plants POST body.
 * Returns { valid: boolean, errors: string[] }
 */
export function validateRecommendInput(body) {
  const errors = [];
  const { temperature, space, sunlight, water } = body;

  // -------------------------
  // Temperature validation
  // -------------------------
  if (temperature === undefined || temperature === null) {
    errors.push('temperature is required.');
  } else if (typeof temperature !== 'number' || isNaN(temperature)) {
    errors.push('temperature must be a number.');
  } else if (temperature < -20 || temperature > 60) {
    errors.push('temperature must be between -20 and 60°C.');
  }

  // -------------------------
  // Space validation
  // -------------------------
  if (!space) {
    errors.push('space is required.');
  } else if (!VALID_SPACES.includes(space)) {
    errors.push(`space must be one of: ${VALID_SPACES.join(', ')}.`);
  }

  // -------------------------
  // Sunlight validation
  // -------------------------
  if (!sunlight) {
    errors.push('sunlight is required.');
  } else if (!VALID_SUNLIGHT.includes(sunlight)) {
    errors.push(`sunlight must be one of: ${VALID_SUNLIGHT.join(', ')}.`);
  }

  // -------------------------
  // Water validation
  // -------------------------
  if (!water) {
    errors.push('water is required.');
  } else if (!VALID_WATER.includes(water)) {
    errors.push(`water must be one of: ${VALID_WATER.join(', ')}.`);
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}