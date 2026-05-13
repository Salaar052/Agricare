// ============================================
// FILE 1: services/crop_recommendation/geminiCropService.js
// ============================================

import axios from "axios";

function stripCodeFences(text) {
  if (!text) return text;
  return String(text)
    .trim()
    .replace(/```json\n?/gi, "")
    .replace(/```\n?/g, "")
    .trim();
}

function tryParseJsonLoose(text) {
  const cleaned = stripCodeFences(text);
  if (!cleaned) return null;

  try {
    return JSON.parse(cleaned);
  } catch {
    // Try to salvage if Gemini adds extra text.
    const first = cleaned.indexOf("{");
    const last = cleaned.lastIndexOf("}");
    if (first >= 0 && last > first) {
      const slice = cleaned.slice(first, last + 1);
      try {
        return JSON.parse(slice);
      } catch {
        return null;
      }
    }
    return null;
  }
}

function getPakistanNowIso() {
  try {
    const parts = new Intl.DateTimeFormat("en-CA", {
      timeZone: "Asia/Karachi",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).formatToParts(new Date());
    const byType = Object.fromEntries(parts.map((p) => [p.type, p.value]));
    // en-CA yields YYYY-MM-DD via parts
    return `${byType.year}-${byType.month}-${byType.day}`;
  } catch {
    return new Date().toISOString().slice(0, 10);
  }
}

function inferPakistanSeason({ month }) {
  // Approximate national seasons used by farmers.
  // month: 1-12
  if (!month || month < 1 || month > 12) {
    return { name: "Unknown", window: "", notes: "" };
  }

  // Common framing:
  // - Rabi: Oct–Mar (wheat, gram, mustard, many vegetables)
  // - Kharif: Apr–Sep (cotton, rice, maize, sugarcane start)
  // - Zaid: Mar–May (short spring/summer vegetables, fodders)
  if ([10, 11, 12, 1, 2, 3].includes(month)) {
    return {
      name: "Rabi",
      window: "Oct–Mar",
      notes: "Cooler season in Pakistan; wheat/gram/mustard are common.",
    };
  }
  if ([4, 5, 6, 7, 8, 9].includes(month)) {
    return {
      name: "Kharif",
      window: "Apr–Sep",
      notes: "Warmer/wet season; rice/cotton/maize are common.",
    };
  }
  return { name: "Zaid", window: "Mar–May", notes: "Short season between Rabi and Kharif." };
}

function normalizeSoilData(soilData) {
  if (!soilData || typeof soilData !== "object") return {};
  // Keep only known fields but don't hard-require them.
  const pick = (k) => (soilData[k] === undefined ? null : soilData[k]);
  return {
    N: pick("N"),
    P: pick("P"),
    K: pick("K"),
    ph: pick("ph"),
    temperature: pick("temperature"),
    humidity: pick("humidity"),
    rainfall: pick("rainfall"),
    ec: pick("ec"),
    organicMatter: pick("organicMatter"),
    texture: pick("texture"),
  };
}

function escapeForJsonString(value) {
  if (value === null || value === undefined) return "";
  return String(value)
    .replace(/\\/g, "\\\\")
    .replace(/\"/g, "\\\"")
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\r")
    .replace(/\t/g, "\\t");
}

function buildFallbackPlan({ cropName, planType, meta }) {
  const crop = cropName || "your crop";
  const safeType = (planType || "complete").toString();
  const seasonText = meta?.season?.name ? ` (${meta.season.name})` : "";

  const base = {
    cropName: crop,
    meta: {
      ...meta,
      planTypeRequested: safeType,
      fallback: true,
    },
    summary: {
      title: `${crop} guidance${seasonText}`,
      bullets: [
        "Safe fallback summary (AI response unavailable).",
        "Use local agri extension recommendations for exact doses.",
        "For pesticides: use only registered products and follow label directions.",
      ],
    },
    warnings: [
      "Always wear PPE when applying pesticides/fertilizers.",
      "Observe pre-harvest interval (PHI) and re-entry interval (REI).",
    ],
  };

  if (safeType === "irrigation") {
    return {
      ...base,
      irrigation: {
        waterNeeds: [
          "Increase frequency during hot/dry spells",
          "Reduce irrigation after rainfall",
          "Avoid waterlogging unless the crop requires standing water",
        ],
        criticalPeriods: ["Establishment", "Flowering", "Filling stage"],
        schedule: [
          {
            stage: "Establishment",
            timing: "0–2 weeks",
            frequency: "Light irrigation as needed",
            method: "Furrow/bed",
            water: "Keep soil moist (not flooded)",
            bullets: ["Irrigate early morning/evening", "Ensure drainage after rain"],
          },
          {
            stage: "Critical stage",
            timing: "Flowering / fruiting",
            frequency: "Do not allow moisture stress",
            method: "Furrow/bed/drip",
            water: "Increase in heatwaves",
            bullets: ["Don’t skip irrigations", "Mulch where possible"],
          },
        ],
        doDonts: [
          "Do: check soil moisture before irrigating",
          "Do: irrigate in cool hours",
          "Don’t: over-irrigate (root disease + nutrient loss)",
        ],
      },
    };
  }

  if (safeType === "pesticides") {
    return {
      ...base,
      fertilizers: [
        {
          name: "Urea (Nitrogen)",
          stage: "Vegetative",
          dose: "Split dose (per local recommendation)",
          method: "Broadcast then irrigate",
          bullets: ["Avoid application before heavy rain", "Do not over-apply"],
        },
        {
          name: "DAP/SSP (Phosphorus)",
          stage: "Basal (at sowing)",
          dose: "As per soil test/local recommendation",
          method: "Band placement near seed line",
          bullets: ["Improves root growth", "Consider zinc/boron if deficiency"],
        },
      ],
      pesticides: [
        {
          target: "Sucking pests (aphids/whitefly) — if present",
          activeIngredient: "Choose registered active ingredient for the crop",
          when: "Spray only after scouting/threshold",
          dose: "Follow label (per acre)",
          safety: ["Wear gloves/mask", "Observe PHI", "Avoid spraying in wind"],
          bullets: ["Prefer IPM first", "Rotate mode of action"],
        },
      ],
      ipm: ["Scout twice weekly", "Use sticky traps", "Remove heavily infested leaves"],
    };
  }

  return {
    ...base,
    stages: [
      {
        stage: "Land prep & sowing",
        duration: "Week 0–1",
        bullets: ["Level field", "Use recommended seed", "Seed treatment if advised"],
      },
      {
        stage: "Vegetative growth",
        duration: "Week 2–6",
        bullets: ["Weed control", "Split nitrogen", "Irrigate as needed"],
      },
      {
        stage: "Flowering / critical stage",
        duration: "Mid season",
        bullets: ["No water stress", "Scout pests", "Balanced nutrition"],
      },
      {
        stage: "Maturity & harvest",
        duration: "Final weeks",
        bullets: ["Harvest at correct maturity", "Dry/grade produce", "Store safely"],
      },
    ],
    quickTips: [
      "Keep notes: sowing date, irrigations, sprays",
      "Avoid unnecessary pesticide sprays",
      "After heavy rain, check waterlogging and disease",
    ],
  };
}

/**
 * Generate detailed crop growth plan using Gemini AI
 * @param {string} cropName - Name of the recommended crop
 * @param {Object} soilData - Soil and environmental parameters
 * @returns {Object} - {success: boolean, growthPlan?: Object, error?: string}
 */
export async function generateCropGrowthPlan(cropName, soilData, options = {}) {
  let planType = "complete";
  let meta = null;
  try {
    // Validate API key
    if (!process.env.GEMINI_API_KEY) {
      return {
        success: false,
        error: "Gemini API key is not configured"
      };
    }

    // Validate inputs
    if (!cropName || typeof cropName !== 'string') {
      return {
        success: false,
        error: "Valid crop name is required"
      };
    }

    planType = (options?.planType || "complete").toString();
    const location = options?.location && typeof options.location === "object" ? options.location : null;
    const weather = options?.weather && typeof options.weather === "object" ? options.weather : null;
    const providedSeason = options?.season && typeof options.season === "object" ? options.season : null;

    const pkDateIso = options?.pakistanDateIso || getPakistanNowIso();
    const month = Number(String(pkDateIso).slice(5, 7)) || null;
    const inferredSeason = inferPakistanSeason({ month });
    const season = providedSeason || inferredSeason;

    const soil = normalizeSoilData(soilData);

    meta = {
      region: "Pakistan",
      pakistanDate: pkDateIso,
      season,
      location: location
        ? {
            label: location.label || location.locationLabel || null,
            lat: location.lat ?? location.latitude ?? null,
            lng: location.lng ?? location.longitude ?? null,
          }
        : null,
      weather: weather
        ? {
            temperatureC: weather.temperatureC ?? weather.tempC ?? null,
            humidityPct: weather.humidityPct ?? weather.humidity ?? null,
            rainfallMm: weather.rainfallMm ?? weather.rainfall ?? null,
            windSpeedKmh: weather.windSpeedKmh ?? weather.wind ?? null,
          }
        : null,
    };

    // Build Pakistan-focused prompt for detailed growth plan
    const safeLocationLabel = escapeForJsonString(meta.location?.label || "");
    const safeSeasonName = escapeForJsonString(season?.name || "Unknown");
    const safeSeasonWindow = escapeForJsonString(season?.window || "");
    const safeSeasonNotes = escapeForJsonString(season?.notes || "");

    const schemaForPlanType = (() => {
      if (planType === "irrigation") {
        return `{
  "cropName": "${cropName}",
  "meta": {
    "region": "Pakistan",
    "pakistanDate": "${pkDateIso}",
    "season": {"name": "${safeSeasonName}", "window": "${safeSeasonWindow}", "notes": "${safeSeasonNotes}"},
    "location": {"label": "${safeLocationLabel}", "lat": ${meta.location?.lat ?? null}, "lng": ${meta.location?.lng ?? null}},
    "weather": {"temperatureC": ${meta.weather?.temperatureC ?? null}, "humidityPct": ${meta.weather?.humidityPct ?? null}, "rainfallMm": ${meta.weather?.rainfallMm ?? null}},
    "planTypeRequested": "irrigation"
  },
  "summary": {"title": "1-line summary", "bullets": ["3-6 bullets"]},
  "irrigation": {
    "waterNeeds": ["3-6 bullets"],
    "criticalPeriods": ["2-5 bullets"],
    "schedule": [
      {"stage": "Stage", "timing": "0-2 weeks", "frequency": "Short", "method": "Short", "water": "Short", "bullets": ["2-5 bullets"]}
    ],
    "doDonts": ["4-8 bullets"]
  },
  "warnings": ["2-6 bullets"]
}`;
      }

      if (planType === "pesticides") {
        return `{
  "cropName": "${cropName}",
  "meta": {
    "region": "Pakistan",
    "pakistanDate": "${pkDateIso}",
    "season": {"name": "${safeSeasonName}", "window": "${safeSeasonWindow}"},
    "location": {"label": "${safeLocationLabel}", "lat": ${meta.location?.lat ?? null}, "lng": ${meta.location?.lng ?? null}},
    "planTypeRequested": "pesticides"
  },
  "summary": {"title": "1-line summary", "bullets": ["3-6 bullets"]},
  "fertilizers": [
    {"name": "Urea/DAP/SOP etc", "stage": "Stage", "dose": "Per acre", "method": "Short", "bullets": ["2-5 bullets"]}
  ],
  "pesticides": [
    {"target": "Pest/disease", "activeIngredient": "Active ingredient only", "when": "Trigger", "dose": "Follow label", "safety": ["3-6 bullets"], "bullets": ["2-5 bullets"]}
  ],
  "ipm": ["4-8 bullets"],
  "warnings": ["2-6 bullets; mention registered products, label, PPE, PHI"]
}`;
      }

      return `{
  "cropName": "${cropName}",
  "meta": {
    "region": "Pakistan",
    "pakistanDate": "${pkDateIso}",
    "season": {"name": "${safeSeasonName}", "window": "${safeSeasonWindow}"},
    "location": {"label": "${safeLocationLabel}", "lat": ${meta.location?.lat ?? null}, "lng": ${meta.location?.lng ?? null}},
    "planTypeRequested": "complete"
  },
  "summary": {"title": "1-line summary", "bullets": ["3-6 bullets"]},
  "stages": [
    {"stage": "Stage", "duration": "Short", "bullets": ["3-7 bullets"]}
  ],
  "quickTips": ["4-10 bullets"],
  "warnings": ["2-6 bullets"]
}`;
    })();

    const prompt = `You are AgriCare's expert agronomist for PAKISTAN.

  Goal: Generate SHORT, clean, farmer-friendly guidance for Pakistani farmers.

Audience & tone:
- Small/medium farmers in Pakistan
- Simple wording, actionable steps
- Avoid unnecessary scientific jargon

Important safety & compliance:
- For pesticides: mention ACTIVE INGREDIENT names (not brand), advise "use only registered products" and "follow label", PPE, re-entry interval, and pre-harvest interval (PHI).
- Do NOT give unsafe mixing instructions. Prefer IPM (scouting, thresholds, cultural controls) first.

Localization rules (Pakistan):
- Consider Pakistan climate and cropping calendar (Rabi/Kharif/Zaid).
- Use units that farmers understand: per acre (and optionally per hectare), irrigation in hours/turns or mm, and common fertilizer names in Pakistan: Urea, DAP, SOP/MOP, SSP, Zinc Sulphate, Boron.
- Mention canal/tube-well and common irrigation methods (flood/furrow/bed, drip where applicable).

USER INPUTS:
- Selected crop: ${cropName.toUpperCase()}
- Requested focus: ${planType}
- Pakistan date: ${pkDateIso}
- Pakistan season: ${season?.name || 'Unknown'} ${season?.window ? `(${season.window})` : ''}
- Location: ${(meta.location?.label || 'Unknown')} (lat: ${meta.location?.lat ?? 'N/A'}, lng: ${meta.location?.lng ?? 'N/A'})
- Weather snapshot: temp ${meta.weather?.temperatureC ?? 'N/A'}°C, humidity ${meta.weather?.humidityPct ?? 'N/A'}%, rainfall ${meta.weather?.rainfallMm ?? 'N/A'} mm
- Soil / lab values (if available):
  - N: ${soil.N ?? 'N/A'}
  - P: ${soil.P ?? 'N/A'}
  - K: ${soil.K ?? 'N/A'}
  - pH: ${soil.ph ?? 'N/A'}
  - Temperature: ${soil.temperature ?? meta.weather?.temperatureC ?? 'N/A'}
  - Humidity: ${soil.humidity ?? meta.weather?.humidityPct ?? 'N/A'}
  - Rainfall: ${soil.rainfall ?? meta.weather?.rainfallMm ?? 'N/A'}

OUTPUT RULES:
- Respond ONLY with valid JSON. No markdown, no code blocks.
- Keep it SHORT. Use bullets arrays; avoid paragraphs.
- Use active ingredient names only (no brands) and mention registered products/label/PPE/PHI.

Return JSON matching EXACTLY this schema for planType=${planType}:
${schemaForPlanType}

IMPORTANT: Respond ONLY with JSON.`;

    // Call Gemini API
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${process.env.GEMINI_API_KEY}`,
      {
        contents: [{
          role: "user",
          parts: [{ text: prompt }]
        }],
        generationConfig: {
          temperature: 0.3,
          maxOutputTokens: 2500,
          topP: 0.95,
          topK: 40
        }
      },
      {
        timeout: 75000,
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    // Extract response
    let botResponse = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!botResponse) {
      return {
        success: false,
        error: "No response from Gemini AI"
      };
    }

    const growthPlan = tryParseJsonLoose(botResponse);
    if (!growthPlan) {
      console.error("[GeminiCropService] Failed to parse JSON. Raw head:", String(botResponse).slice(0, 500));
      return {
        success: true,
        growthPlan: buildFallbackPlan({ cropName, planType, meta }),
        fallback: true,
        warning: "AI returned an unexpected format — showing a safe fallback plan.",
      };
    }

    // Validate essential fields for the selected plan type
    const hasBase = !!growthPlan.cropName && !!growthPlan.summary;
    const ok = (() => {
      if (!hasBase) return false;
      if (planType === "irrigation") return !!growthPlan.irrigation;
      if (planType === "pesticides") return Array.isArray(growthPlan.fertilizers) || Array.isArray(growthPlan.pesticides);
      return Array.isArray(growthPlan.stages);
    })();

    if (!ok) {
      return {
        success: true,
        growthPlan: buildFallbackPlan({ cropName, planType, meta }),
        fallback: true,
        warning: "AI response was incomplete — showing a safe fallback plan.",
      };
    }

    // Ensure meta exists for frontend.
    if (!growthPlan.meta || typeof growthPlan.meta !== "object") {
      growthPlan.meta = { ...meta, planTypeRequested: planType };
    }

    return {
      success: true,
      growthPlan: growthPlan,
      fallback: false
    };

  } catch (error) {
    console.error("Gemini Crop Service Error:", error.response?.data || error.message);

    // Handle specific error types
    if (error.response) {
      const errorMessage = error.response.data?.error?.message || "Gemini API request failed";
      return {
        success: true,
        growthPlan: buildFallbackPlan({ cropName, planType, meta }),
        fallback: true,
        warning: errorMessage,
      };
    } else if (error.request) {
      return {
        success: true,
        growthPlan: buildFallbackPlan({ cropName, planType, meta }),
        fallback: true,
        warning: "No response from Gemini API. Please check your internet connection.",
      };
    } else if (error.code === 'ECONNABORTED') {
      return {
        success: true,
        growthPlan: buildFallbackPlan({ cropName, planType, meta }),
        fallback: true,
        warning: "Request timeout. The AI is taking too long. Showing a fallback plan.",
      };
    } else {
      return {
        success: true,
        growthPlan: buildFallbackPlan({ cropName, planType, meta }),
        fallback: true,
        warning: "Failed to generate AI plan. Showing a fallback plan.",
      };
    }
  }
}

