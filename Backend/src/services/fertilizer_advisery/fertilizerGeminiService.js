import { askGemini } from "../ai_chatbot/geminiService.js";

/**
 * Dynamic fertilizer & pesticide advisory via Gemini from validated soil/weather data.
 */
export async function getGeminiFertilizerAdvisory(crop, soil, weather, ruleHints = null) {
  const hints = ruleHints
    ? `\nRule-based baseline (use as hints, improve with your expertise):\n${JSON.stringify(ruleHints)}\n`
    : "";

  const prompt =
    `You are an expert agronomist for AgriCare. Analyze this farm data and provide practical fertilizer and pest recommendations.\n\n` +
    `Crop: ${crop}\n` +
    `Soil (mg/kg): Nitrogen=${soil.nitrogen}, Phosphorus=${soil.phosphorus}, Potassium=${soil.potassium}` +
    (soil.ph != null ? `, pH=${soil.ph}` : "") +
    `\nWeather: Temperature=${weather.temperature}°C, Humidity=${weather.humidity}%\n` +
    hints +
    `\nReply with ONLY valid JSON (no markdown):\n` +
    `{\n` +
    `  "summary": "<2-3 sentence overview for the farmer>",\n` +
    `  "fertilizers": ["<fertilizer name — short reason>", ...],\n` +
    `  "pesticides": [{"issue":"<pest/disease risk>","solution":"<product or action>"}]\n` +
    `}\n` +
    `Rules:\n` +
    `- Recommend fertilizers only when nutrients are genuinely deficient for this crop\n` +
    `- Include 0-3 pesticide alerts based on weather risks\n` +
    `- Use simple language; no code or markdown`;

  const result = await askGemini(prompt, []);

  if (!result.success || !result.response) {
    return {
      success: false,
      error: result.error || "AI advisory unavailable",
    };
  }

  const text = String(result.response).trim();
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) {
    return { success: false, error: "Could not parse AI advisory response" };
  }

  try {
    const obj = JSON.parse(match[0]);
    const summary =
      typeof obj.summary === "string" ? obj.summary.trim() : "";
    const fertilizers = Array.isArray(obj.fertilizers)
      ? obj.fertilizers
          .filter((f) => typeof f === "string" && f.trim())
          .map((f) => f.trim())
      : [];
    const pesticides = Array.isArray(obj.pesticides)
      ? obj.pesticides
          .filter((p) => p && typeof p === "object")
          .map((p) => ({
            issue: String(p.issue || "").trim(),
            solution: String(p.solution || "").trim(),
          }))
          .filter((p) => p.issue && p.solution)
      : [];

    return {
      success: true,
      summary,
      fertilizers,
      pesticides,
      aiGenerated: true,
    };
  } catch {
    return { success: false, error: "Invalid AI advisory format" };
  }
}
