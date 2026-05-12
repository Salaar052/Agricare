import { HARVEST_BASE_DATES, DEFAULT_HARVEST_BASE, HARVEST_ADJUSTMENTS } from '../../utils/crop_rules.js';

/**
 * Computes the base harvest date for a given crop.
 * Defaults to the current year.
 * @param {string} crop
 * @returns {Date}
 */
const getBaseDate = (crop) => {
  const key = crop.toLowerCase().trim();
  const base = HARVEST_BASE_DATES[key] || DEFAULT_HARVEST_BASE;
  const year = new Date().getFullYear();
  return new Date(year, base.month - 1, base.day); // month is 0-indexed
};

/**
 * Formats a Date object as YYYY-MM-DD.
 * @param {Date} date
 * @returns {string}
 */
const formatDate = (date) => date.toISOString().split('T')[0];

/**
 * Analyzes forecast data and returns adjustment details.
 * @param {Array<{temp: number, rain: number}>} forecast
 * @returns {{ adjustmentDays: number, reasons: string[] }}
 */
const analyzeForecast = (forecast) => {
  let adjustmentDays = 0;
  const reasons = [];

  const {
    rainPenaltyDays,
    highTempPenaltyDays,
    highTempThreshold,
    highTempMinDays,
    coldTempBonusDays,
    coldTempThreshold,
  } = HARVEST_ADJUSTMENTS;

  // Check for rain in forecast
  const hasRain = forecast.some((day) => day.rain > 0);
  if (hasRain) {
    adjustmentDays -= rainPenaltyDays;
    reasons.push(`Harvest ${rainPenaltyDays} days earlier due to expected rain`);
  }

  // Check for prolonged high temperature
  const hotDays = forecast.filter((day) => day.temp > highTempThreshold).length;
  if (hotDays >= highTempMinDays) {
    adjustmentDays -= highTempPenaltyDays;
    reasons.push(`Harvest ${highTempPenaltyDays} days earlier due to extreme heat (${hotDays} days above ${highTempThreshold}°C)`);
  }

  // Check for cold temperature
  const coldDays = forecast.filter((day) => day.temp < coldTempThreshold).length;
  if (coldDays > 0) {
    adjustmentDays += coldTempBonusDays;
    reasons.push(`Harvest delayed by ${coldTempBonusDays} days due to cold temperatures`);
  }

  return { adjustmentDays, reasons };
};

/**
 * Main harvest suggestion service.
 * @param {string} crop
 * @param {Array<{temp: number, rain: number}>} forecast
 * @returns {{ harvestDate: string, advice: string, adjustmentDays: number }}
 */
export const getHarvestSuggestion = (crop, forecast) => {
  if (!crop) throw new Error('crop is required.');
  if (!Array.isArray(forecast) || forecast.length === 0) {
    throw new Error('forecast must be a non-empty array.');
  }

  const baseDate = getBaseDate(crop);
  const { adjustmentDays, reasons } = analyzeForecast(forecast);

  // Apply adjustment
  const harvestDate = new Date(baseDate);
  harvestDate.setDate(harvestDate.getDate() + adjustmentDays);

  const advice =
    reasons.length > 0
      ? reasons.join('. ') + '.'
      : 'Conditions are optimal. Harvest on the recommended date.';

  return {
    crop,
    baseDate: formatDate(baseDate),
    harvestDate: formatDate(harvestDate),
    adjustmentDays,
    advice,
  };
};
