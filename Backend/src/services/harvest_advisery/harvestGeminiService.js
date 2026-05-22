import { askGemini } from "../ai_chatbot/geminiService.js";

/**
 * Enhance rule-based harvest plan with Gemini narrative advice.
 */
export async function getGeminiHarvestEnhancement(crop, forecast, ruleResult) {
  const prompt =
    `Crop: ${crop}\n` +
    `3-day forecast: ${JSON.stringify(forecast)}\n` +
    `Rule-based plan: base ${ruleResult.baseDate}, suggested harvest ${ruleResult.harvestDate}, ` +
    `adjustment ${ruleResult.adjustmentDays} days, advice: ${ruleResult.advice}\n\n` +
    `Reply with ONLY valid JSON:\n` +
    `{"advice":"<2-4 practical sentences for the farmer>","harvestDate":"${ruleResult.harvestDate}"}`;

  const result = await askGemini(prompt, []);

  if (!result.success || !result.response) {
    return { success: false, error: result.error };
  }

  const match = String(result.response).match(/\{[\s\S]*\}/);
  if (!match) return { success: false };

  try {
    const obj = JSON.parse(match[0]);
    const advice = typeof obj.advice === "string" ? obj.advice.trim() : "";
    const harvestDate =
      typeof obj.harvestDate === "string" && obj.harvestDate.trim()
        ? obj.harvestDate.trim()
        : ruleResult.harvestDate;
    return { success: true, advice, harvestDate };
  } catch {
    return { success: false };
  }
}
