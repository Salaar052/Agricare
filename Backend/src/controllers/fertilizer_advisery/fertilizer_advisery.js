import { validateSoilAndWeather } from "../../utils/soilValidation.js";
import { getCropInsightForUnlistedName } from "../../services/fertilizer_advisery/cropInsightGemini.js";
import { getGeminiFertilizerAdvisory } from "../../services/fertilizer_advisery/fertilizerGeminiService.js";

/**
 * POST /api/advisory
 * Returns AI-generated fertilizer and pesticide recommendations.
 */
export const getAdvisoryController = async (req, res, next) => {
  try {
    const { crop, soil, weather } = req.body;

    if (!crop || typeof crop !== "string" || !crop.trim()) {
      return res.status(400).json({
        error: 'Invalid request: "crop" must be a non-empty string.',
      });
    }
    if (!soil || typeof soil !== "object") {
      return res.status(400).json({
        error:
          'Invalid request: "soil" must be an object with nitrogen, phosphorus, potassium.',
      });
    }
    if (!weather || typeof weather !== "object") {
      return res.status(400).json({
        error:
          'Invalid request: "weather" must be an object with temperature and humidity.',
      });
    }

    const normalizedSoil = {
      nitrogen: Number(soil.nitrogen),
      phosphorus: Number(soil.phosphorus),
      potassium: Number(soil.potassium),
      ...(soil.ph != null && soil.ph !== ""
        ? { ph: Number(soil.ph) }
        : {}),
    };
    const normalizedWeather = {
      temperature: Number(weather.temperature),
      humidity: Number(weather.humidity),
    };

    const validation = validateSoilAndWeather(normalizedSoil, normalizedWeather);
    if (!validation.valid) {
      return res.status(400).json({
        error: validation.errors.join(" "),
        errors: validation.errors,
      });
    }

    const aiResult = await getGeminiFertilizerAdvisory(
      crop.trim(),
      normalizedSoil,
      normalizedWeather
    );

    if (!aiResult.success) {
      return res.status(503).json({
        error:
          aiResult.error ||
          "AI advisory service is temporarily unavailable. Please try again.",
      });
    }

    const cropInsight = await getCropInsightForUnlistedName(crop.trim());

    return res.status(200).json({
      crop: crop.trim(),
      fertilizers: aiResult.fertilizers,
      pesticides: aiResult.pesticides,
      aiSummary: aiResult.summary,
      aiGenerated: true,
      cropInsight: cropInsight?.tip ?? null,
      cropDisplayName: cropInsight?.displayName ?? null,
    });
  } catch (error) {
    next(error);
  }
};
