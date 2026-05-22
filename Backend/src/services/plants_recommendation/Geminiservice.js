import axios from "axios";

const buildPrompt = (userInput, plantNames) => {
  const { temperature, space, sunlight, water } = userInput;
  return `User's conditions:
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

export async function getPlantExplanations(userInput, plants) {
  const plantNames = plants.map((p) => p.name);
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey) {
    console.warn("[GeminiService] GEMINI_API_KEY not set — using fallback data.");
    return buildFallback(plantNames);
  }

  try {
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
        headers: { "Content-Type": "application/json" },
      }
    );

    const rawText = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!rawText) {
      console.error("[GeminiService] Empty response from Gemini.");
      return buildFallback(plantNames);
    }

    const clean = rawText
      .replace(/```json\s*/gi, "")
      .replace(/```\s*/g, "")
      .trim();

    const parsed = JSON.parse(clean);
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
    return buildFallback(plantNames);
  }
}
