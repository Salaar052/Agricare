
import { getAdvisory } from '../../services/fertilizer_advisery/fertilizer_advisery.js';
import { getCropInsightForUnlistedName } from '../../services/fertilizer_advisery/cropInsightGemini.js';

/**
 * POST /api/advisory
 * Returns fertilizer and pesticide recommendations based on crop, soil, and weather.
 */
export const getAdvisoryController = async (req, res, next) => {
  try {
    const { crop, soil, weather } = req.body;

    if (!crop || typeof crop !== 'string') {
      return res.status(400).json({ error: 'Invalid request: "crop" must be a non-empty string.' });
    }
    if (!soil || typeof soil !== 'object') {
      return res.status(400).json({ error: 'Invalid request: "soil" must be an object with nitrogen, phosphorus, potassium.' });
    }
    if (!weather || typeof weather !== 'object') {
      return res.status(400).json({ error: 'Invalid request: "weather" must be an object with temperature and humidity.' });
    }

    const result = getAdvisory(crop, soil, weather);
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
