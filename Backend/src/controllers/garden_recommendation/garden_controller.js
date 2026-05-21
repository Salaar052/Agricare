// src/controllers/garden/garden.controller.js
// ============================================================
// Garden Recommendation Controller
// Orchestrates: validation → rule engine → Gemini AI → response
// ============================================================

import { recommendPlants } from "../../services/plants_recommendation/plants_filter.js";
import { getPlantExplanations } from "../../services/plants_recommendation/Geminiservice.js";

console.log("Loading Garden Recommendation Controller...");

// ── Validation Helpers ───────────────────────────────────────
const VALID_SPACES = ["balcony", "garden", "indoor"];
const VALID_SUNLIGHT = ["full", "partial", "shade"];
const VALID_WATER = ["low", "medium", "high"];

const validateInput = ({ temperature, space, sunlight, water, location }) => {
  const errors = [];

  if (temperature === undefined || temperature === null) {
    errors.push("temperature is required.");
  } else if (typeof temperature !== "number" || isNaN(temperature)) {
    errors.push("temperature must be a number.");
  } else if (temperature < -20 || temperature > 60) {
    errors.push("temperature must be between -20°C and 60°C.");
  }

  if (!space) {
    errors.push("space is required.");
  } else if (!VALID_SPACES.includes(space)) {
    errors.push(`space must be one of: ${VALID_SPACES.join(", ")}.`);
  }

  if (!sunlight) {
    errors.push("sunlight is required.");
  } else if (!VALID_SUNLIGHT.includes(sunlight)) {
    errors.push(`sunlight must be one of: ${VALID_SUNLIGHT.join(", ")}.`);
  }

  if (!water) {
    errors.push("water is required.");
  } else if (!VALID_WATER.includes(water)) {
    errors.push(`water must be one of: ${VALID_WATER.join(", ")}.`);
  }

  if (location !== undefined && location !== null) {
    if (typeof location !== "object") {
      errors.push("location must be an object if provided.");
    } else {
      const { lat, lng, label } = location;
      if (lat !== undefined && (typeof lat !== "number" || Number.isNaN(lat))) {
        errors.push("location.lat must be a number.");
      }
      if (lng !== undefined && (typeof lng !== "number" || Number.isNaN(lng))) {
        errors.push("location.lng must be a number.");
      }
      if (label !== undefined && typeof label !== "string") {
        errors.push("location.label must be a string.");
      }
    }
  }

  return errors;
};

// ── POST /api/v1/garden/recommend ───────────────────────────
const recommendGardenPlants = async (req, res) => {
  console.log("[GardenController] Received recommendation request:", {
    body: req.body,
  });
  try {
    // 1. Validate request body
    const errors = validateInput(req.body);
    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Validation failed.",
        errors,
      });
    }

    const userInput = {
      temperature: req.body.temperature,
      space: req.body.space,
      sunlight: req.body.sunlight,
      water: req.body.water,
      location: req.body.location,
    };

    // 2. Run rule-based filtering + scoring (zero AI)
    const { plants, message } = recommendPlants(userInput);

    if (plants.length === 0) {
      return res.status(200).json({
        success: true,
        plants: [],
        message: message ?? "No plants matched your conditions.",
      });
    }

    // 3. Send only top-3 to Gemini for explanation text
    const aiMap = await getPlantExplanations(userInput, plants);

    // 4. Merge rule-based data with AI explanations
    const result = plants.map((plant) => ({
      id: plant.id,
      name: plant.name,
      emoji: plant.emoji,
      category: plant.category,
      score: plant.score,
      maxScore: 11,
      conditions: {
        temp_min: plant.temp_min,
        temp_max: plant.temp_max,
        space: plant.space,
        sunlight: plant.sunlight,
        water: plant.water,
      },
      ai: aiMap[plant.name] ?? {
        pros: [],
        cons: [],
        tips: "No AI explanation available at this time.",
      },
    }));

    return res.status(200).json({
      success: true,
      userInput,
      count: result.length,
      plants: result,
    });
  } catch (error) {
    console.error("[GardenController] Unhandled error:", error.message);
    return res.status(500).json({
      success: false,
      message: "Internal server error. Please try again.",
    });
  }
};

// ── GET /api/v1/garden/plants ────────────────────────────────
// Returns the full dataset (useful for debugging / admin UI)
//import plants from "../../services/plants_recommendation/plants.json";
const plants="will do later";
const getAllPlants = (_req, res) => {
  return res.status(200).json({
    success: true,
    count: plants.length,
    plants,
  });
};

// ── GET /api/v1/garden/health ────────────────────────────────
const healthCheck = (_req, res) => {
  return res.status(200).json({
    success: true,
    service: "Garden Recommendation API",
    geminiConfigured: !!process.env.GEMINI_API_KEY,
    timestamp: new Date().toISOString(),
  });
};

export { recommendGardenPlants, getAllPlants, healthCheck };