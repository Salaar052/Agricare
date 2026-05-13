
import { getHarvestSuggestion } from '../../services/harvest_advisery/harvest_advisery.js';
import { getCropInsightForUnlistedName } from '../../services/fertilizer_advisery/cropInsightGemini.js';

/**
 * POST /api/harvest
 * Returns optimal harvest date and advice based on crop type and weather forecast.
 */
export const getHarvestController = async (req, res, next) => {
  try {
    const { crop, forecast } = req.body;

    if (!crop || typeof crop !== 'string') {
      return res.status(400).json({ error: 'Invalid request: "crop" must be a non-empty string.' });
    }
    if (!Array.isArray(forecast) || forecast.length === 0) {
      return res.status(400).json({ error: 'Invalid request: "forecast" must be a non-empty array of {temp, rain} objects.' });
    }

    const result = getHarvestSuggestion(crop, forecast);
    const cropInsight = await getCropInsightForUnlistedName(crop);

    return res.status(200).json({
      ...result,
      cropInsight: cropInsight?.tip ?? null,
      cropDisplayName: cropInsight?.displayName ?? null,
    });
  } catch (error) {
    next(error);
  }
};
