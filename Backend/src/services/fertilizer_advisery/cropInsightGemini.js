import { askGemini } from "../ai_chatbot/geminiService.js";

/** Crops handled locally without calling Gemini */
const LISTED_CROPS = new Set([
  "rice",
  "wheat",
  "maize",
  "cotton",
  "sugarcane",
  "potato",
  "tomato",
]);

/**
 * For crop names outside the preset list, ask Gemini for a short display name + tip.
 * Returns null if listed, on error, or if Gemini is not configured.
 */
export async function getCropInsightForUnlistedName(rawName) {
  const trimmed = (rawName || "").trim();
  if (!trimmed) return null;
  if (LISTED_CROPS.has(trimmed.toLowerCase())) return null;

  const r = await askGemini(
    `The farmer entered this crop: "${trimmed}". It is NOT in our preset list (rice, wheat, maize, cotton, sugarcane, potato, tomato).\n` +
      `Reply with ONLY valid JSON (no markdown): {"displayName":"<short English crop name>","tip":"<one practical sentence for fertilizer/pest planning in smallholder farming>"}\n` +
      `If the text is not a crop, use {"displayName":"Unknown","tip":"Please enter a recognizable crop name."}`,
    []
  );

  if (!r.success || !r.response) return null;

  const text = String(r.response).trim();
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) return null;

  try {
    const obj = JSON.parse(match[0]);
    const displayName =
      typeof obj.displayName === "string" ? obj.displayName.trim() : "";
    const tip = typeof obj.tip === "string" ? obj.tip.trim() : "";
    if (!displayName && !tip) return null;
    return {
      displayName: displayName || trimmed,
      tip: tip || "",
    };
  } catch {
    return null;
  }
}
