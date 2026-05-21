/**
 * Validates soil and weather inputs for fertilizer advisory.
 * Returns { valid: true } or { valid: false, errors: string[] }.
 */
const RANGES = {
  nitrogen: { min: 0, max: 500, label: "Nitrogen" },
  phosphorus: { min: 0, max: 500, label: "Phosphorus" },
  potassium: { min: 0, max: 500, label: "Potassium" },
  temperature: { min: -10, max: 55, label: "Temperature" },
  humidity: { min: 0, max: 100, label: "Humidity" },
  ph: { min: 0, max: 14, label: "pH" },
};

const isFiniteNumber = (v) => typeof v === "number" && Number.isFinite(v);

export const validateSoilAndWeather = (soil, weather) => {
  const errors = [];

  if (!soil || typeof soil !== "object") {
    return { valid: false, errors: ["Soil data is required."] };
  }
  if (!weather || typeof weather !== "object") {
    return { valid: false, errors: ["Weather data is required."] };
  }

  for (const key of ["nitrogen", "phosphorus", "potassium"]) {
    const value = soil[key];
    const range = RANGES[key];
    if (!isFiniteNumber(value)) {
      errors.push(`${range.label} must be a valid number.`);
      continue;
    }
    if (value < range.min || value > range.max) {
      errors.push(
        `${range.label} must be between ${range.min} and ${range.max} mg/kg.`
      );
    }
  }

  if (soil.ph !== undefined && soil.ph !== null && soil.ph !== "") {
    const ph = Number(soil.ph);
    if (!isFiniteNumber(ph)) {
      errors.push("pH must be a valid number.");
    } else if (ph < RANGES.ph.min || ph > RANGES.ph.max) {
      errors.push(`pH must be between ${RANGES.ph.min} and ${RANGES.ph.max}.`);
    }
  }

  const temp = weather.temperature;
  if (!isFiniteNumber(temp)) {
    errors.push("Temperature must be a valid number.");
  } else if (temp < RANGES.temperature.min || temp > RANGES.temperature.max) {
    errors.push(
      `Temperature must be between ${RANGES.temperature.min}°C and ${RANGES.temperature.max}°C.`
    );
  }

  const humidity = weather.humidity;
  if (!isFiniteNumber(humidity)) {
    errors.push("Humidity must be a valid number.");
  } else if (humidity < RANGES.humidity.min || humidity > RANGES.humidity.max) {
    errors.push(
      `Humidity must be between ${RANGES.humidity.min}% and ${RANGES.humidity.max}%.`
    );
  }

  return errors.length ? { valid: false, errors } : { valid: true };
};

export { RANGES };
