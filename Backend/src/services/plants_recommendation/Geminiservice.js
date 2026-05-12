import axios from "axios";

// ── Prompt Builder ───────────────────────────────────────────
const buildPrompt = (userInput, plantNames) => {
  const { temperature, space, sunlight, water } = userInput;

  return `You are a friendly home gardening assistant. A user wants to grow vegetables at home.

User's conditions:
- Temperature: ${temperature}°C
- Space: ${space}
- Sunlight availability: ${sunlight} sun
- Water availability: ${water}

Our rule-based system has already selected these top plants for the user: ${plantNames.join(", ")}

For EACH plant listed above, provide:
1. pros: 3 short bullet points (beginner-friendly benefits)
2. cons: 2 short bullet points (challenges or limitations)
3. tips: One practical care tip sentence for beginners

Respond ONLY with a valid JSON array in this exact format (no markdown, no explanation, just JSON):
[
  {
    "name": "PlantName",
    "pros": ["pro1", "pro2", "pro3"],
    "cons": ["con1", "con2"],
    "tips": "A practical care tip for beginners."
  }
]

Keep all text concise, simple, and beginner-friendly. Do not include any text outside the JSON array.`;
};

// ── Fallback Data ────────────────────────────────────────────
const buildFallback = (plantNames) => {
  const fallback = {};
  plantNames.forEach((name) => {
    fallback[name] = {
      pros: [
        "Good choice for home growing",
        "Nutritious and fresh when harvested",
        "Manageable for beginners",
      ],
      cons: [
        "Requires regular attention",
        "May need occasional pest control",
      ],
      tips: "Water regularly, ensure good drainage, and give adequate sunlight.",
    };
  });
  return fallback;
};

// ── Main Export ──────────────────────────────────────────────
/**
 * Ask Gemini to explain the already-selected top 3 plants.
 * Mirrors the exact same axios pattern as AgriCare's askGemini().
 *
 * @param {object} userInput - { temperature, space, sunlight, water }
 * @param {Array}  plants    - top 3 plants from plantEngine.service.js
 * @returns {object} map of { plantName -> { pros, cons, tips } }
 */
export async function getPlantExplanations(userInput, plants) {
  const plantNames = plants.map((p) => p.name);

  // Read key at call-time (not module load-time) so dotenv is always ready
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey) {
    console.warn("[GeminiService] GEMINI_API_KEY not set — using fallback data.");
    return buildFallback(plantNames);
  }

  try {
    // ── Exact same call structure as askGemini() ─────────────
    const res = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${apiKey}`,
      {
        contents: [
          {
            role: "user",
            parts: [{ text: buildPrompt(userInput, plantNames) }],
          },
        ],
      },
      {
        timeout: 30000,
        headers: {
          "Content-Type": "application/json",
        },
      }
    );

    // ── Exact same extraction path as askGemini() ────────────
    const rawText = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!rawText) {
      console.error("[GeminiService] Empty response from Gemini.");
      return buildFallback(plantNames);
    }

    // Strip markdown fences if Gemini wraps output in ```json ... ```
    const clean = rawText
      .replace(/```json\s*/gi, "")
      .replace(/```\s*/g, "")
      .trim();

    const parsed = JSON.parse(clean);

    // Convert array → lookup map keyed by plant name
    const aiMap = {};
    parsed.forEach((item) => {
      if (item.name) {
        aiMap[item.name] = {
          pros: Array.isArray(item.pros) ? item.pros : [],
          cons: Array.isArray(item.cons) ? item.cons : [],
          tips: typeof item.tips === "string" ? item.tips : "",
        };
      }
    });

    return aiMap;

  } catch (error) {
    console.error("[GeminiService] Gemini API Error:", error.response?.data || error.message);

    // ── Exact same error-handling branches as askGemini() ────
    if (error.response) {
      const msg = error.response.data?.error?.message || "Gemini API request failed";
      console.error("[GeminiService] API error:", msg);
    } else if (error.request) {
      console.error("[GeminiService] No response from Gemini — check internet connection.");
    } else if (error.code === "ECONNABORTED") {
      console.error("[GeminiService] Request timed out.");
    } else {
      console.error("[GeminiService] Unexpected error:", error.message);
    }

    // Always degrade gracefully — app still shows rule-based results
    return buildFallback(plantNames);
  }
}