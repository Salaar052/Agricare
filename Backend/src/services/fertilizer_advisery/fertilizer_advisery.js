import { FERTILIZER_THRESHOLDS, PESTICIDE_CONDITIONS } from '../../utils/crop_rules.js';

/**
 * Determines fertilizer recommendations based on soil nutrient levels.
 * @param {Object} soil - { nitrogen, phosphorus, potassium }
 * @returns {string[]} Array of recommended fertilizers
 */
const getFertilizerRecommendations = (soil) => {
  const recommendations = [];

  const { nitrogen = 0, phosphorus = 0, potassium = 0 } = soil;

  if (nitrogen < FERTILIZER_THRESHOLDS.nitrogen.threshold) {
    recommendations.push(FERTILIZER_THRESHOLDS.nitrogen.recommendation);
  }
  if (phosphorus < FERTILIZER_THRESHOLDS.phosphorus.threshold) {
    recommendations.push(FERTILIZER_THRESHOLDS.phosphorus.recommendation);
  }
  if (potassium < FERTILIZER_THRESHOLDS.potassium.threshold) {
    recommendations.push(FERTILIZER_THRESHOLDS.potassium.recommendation);
  }

  return recommendations;
};

/**
 * Determines pesticide recommendations based on weather conditions.
 * @param {Object} weather - { temperature, humidity }
 * @returns {Array<{issue: string, solution: string}>} Array of pesticide advisories
 */
const getPesticideRecommendations = (weather) => {
  const { temperature = 0, humidity = 0 } = weather;

  return PESTICIDE_CONDITIONS
    .filter((condition) => condition.check({ temperature, humidity }))
    .map(({ issue, solution }) => ({ issue, solution }));
};

/**
 * Main advisory service function.
 * @param {string} crop - Crop name
 * @param {Object} soil - Soil nutrient levels
 * @param {Object} weather - Current weather conditions
 * @returns {{ fertilizers: string[], pesticides: Array }}
 */
export const getAdvisory = (crop, soil, weather) => {
  if (!crop || !soil || !weather) {
    throw new Error('crop, soil, and weather fields are required.');
  }

  const fertilizers = getFertilizerRecommendations(soil);
  const pesticides = getPesticideRecommendations(weather);

  return { crop, fertilizers, pesticides };
};
