// src/routes/garden/garden.routes.js
// ============================================================
// Garden Recommendation Routes
// Mounted at: /api/v1/garden  (see app.js)
// ============================================================

import { Router } from "express";
import {
  recommendGardenPlants,
  getAllPlants,
  healthCheck,
} from "../../controllers/garden_recommendation/garden_controller.js";

const router = Router();
console.log("Setting up Garden Recommendation Routes...");

// POST /api/v1/garden/recommend
// Main endpoint — takes user conditions, returns top 3 scored plants + AI tips
router.post("/recommend", recommendGardenPlants);

// GET /api/v1/garden/plants
// Returns the full 20-plant dataset (dev / admin use)
router.get("/plants", getAllPlants);

// GET /api/v1/garden/health
// Service health check
router.get("/health", healthCheck);

export default router;