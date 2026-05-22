import { getHarvestSuggestion } from "../../services/harvest_advisery/harvest_advisery.js";
import { getCropInsightForUnlistedName } from "../../services/fertilizer_advisery/cropInsightGemini.js";
import { getGeminiHarvestEnhancement } from "../../services/harvest_advisery/harvestGeminiService.js";

/**
 * POST /api/harvest — hybrid: rule-based dates + Gemini-enhanced advice.
 */
export const getHarvestController = async (req, res, next) => {
  try {
    const { crop, forecast } = req.body;

    if (!crop || typeof crop !== "string" || !crop.trim()) {
      return res.status(400).json({
        error: 'Invalid request: "crop" must be a non-empty string.',
      });
    }
    if (!Array.isArray(forecast) || forecast.length === 0) {
      return res.status(400).json({
        error:
          'Invalid request: "forecast" must be a non-empty array of {temp, rain} objects.',
      });
    }

    const normalizedForecast = forecast.map((d) => ({
      temp: Number(d.temp),
      rain: Number(d.rain),
    }));

    const ruleResult = getHarvestSuggestion(crop.trim(), normalizedForecast);
    const aiEnhancement = await getGeminiHarvestEnhancement(
      crop.trim(),
      normalizedForecast,
      ruleResult
    );

    const cropInsight = await getCropInsightForUnlistedName(crop.trim());

    return res.status(200).json({
      ...ruleResult,
      harvestDate:
        aiEnhancement.success && aiEnhancement.harvestDate
          ? aiEnhancement.harvestDate
          : ruleResult.harvestDate,
      advice:
        aiEnhancement.success && aiEnhancement.advice
          ? aiEnhancement.advice
          : ruleResult.advice,
      aiGenerated: aiEnhancement.success === true,
      hybrid: true,
      cropInsight: cropInsight?.tip ?? null,
      cropDisplayName: cropInsight?.displayName ?? null,
    });
  } catch (error) {
    next(error);
  }
};
