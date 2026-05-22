import { validateSoilAndWeather } from "../../utils/soilValidation.js";
import { getAdvisory } from "../../services/fertilizer_advisery/fertilizer_advisery.js";
import { getCropInsightForUnlistedName } from "../../services/fertilizer_advisery/cropInsightGemini.js";
import { getGeminiFertilizerAdvisory } from "../../services/fertilizer_advisery/fertilizerGeminiService.js";

/**
 * POST /api/advisory — hybrid: rule engine baseline + Gemini recommendations.
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
      ...(soil.ph != null && soil.ph !== "" ? { ph: Number(soil.ph) } : {}),
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

    const ruleResult = getAdvisory(crop.trim(), normalizedSoil, normalizedWeather);

    const aiResult = await getGeminiFertilizerAdvisory(
      crop.trim(),
      normalizedSoil,
      normalizedWeather,
      {
        fertilizers: ruleResult.fertilizers,
        pesticides: ruleResult.pesticides,
      }
    );

    const cropInsight = await getCropInsightForUnlistedName(crop.trim());

    if (aiResult.success) {
      return res.status(200).json({
        crop: crop.trim(),
        fertilizers: aiResult.fertilizers.length
          ? aiResult.fertilizers
          : ruleResult.fertilizers,
        pesticides: aiResult.pesticides.length
          ? aiResult.pesticides
          : ruleResult.pesticides,
        aiSummary: aiResult.summary,
        aiGenerated: true,
        hybrid: true,
        cropInsight: cropInsight?.tip ?? null,
        cropDisplayName: cropInsight?.displayName ?? null,
      });
    }

    return res.status(200).json({
      ...ruleResult,
      aiSummary: null,
      aiGenerated: false,
      hybrid: true,
      ruleFallback: true,
      cropInsight: cropInsight?.tip ?? null,
      cropDisplayName: cropInsight?.displayName ?? null,
    });
  } catch (error) {
    next(error);
  }
};
