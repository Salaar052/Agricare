// File: src/controllers/cropRecommendation.controller.js

import cropRecommendationService from '../services/cropRecommendation/cropRecommendation.service.js';
import { generateCropGrowthPlan } from '../services/cropRecommendation/geminiCropService.js';
import { extractLabReportValuesFromImage } from '../services/cropRecommendation/labReportExtraction.service.js';
import { getWeatherBasedCropRecommendation } from '../services/cropRecommendation/weatherBasedCropRecommendation.service.js';
/**
 * Crop Recommendation Controller
 * Handles HTTP requests for crop recommendations
 */

/**
 * Get crop recommendation based on soil and environmental data
 * POST /api/v1/crop-recommendation/recommend
 */
export const recommendCrop = async (req, res) => {
  try {
    const result = await cropRecommendationService.getRecommendation(req.body);
    return res.status(200).json(result);
    
  } catch (error) {
    console.error('Controller Error:', error);
    
    const statusCode = error.statusCode || 500;
    
    return res.status(statusCode).json({
      success: false,
      error: error.message,
      ...(error.details && { details: error.details }),
      timestamp: new Date().toISOString()
    });
  }
};

export const getGrowthPlan = async (req, res) => {
  try {
    const { cropName, soilData, planType, context } = req.body || {};

    // Validation
    if (!cropName || typeof cropName !== 'string') {
      return res.status(400).json({
        success: false,
        error: "Crop name is required and must be a string"
      });
    }

    // Soil data is optional here (weather-based flows might not have NPK/pH).
    // If provided, ensure it's an object.
    if (soilData !== undefined && (typeof soilData !== 'object' || soilData === null)) {
      return res.status(400).json({
        success: false,
        error: "soilData must be an object when provided"
      });
    }

    // Optional: planType hints which section the user tapped.
    const safePlanType = typeof planType === 'string' && planType.trim()
      ? planType.trim().toLowerCase()
      : 'complete';

    const safeContext = (context && typeof context === 'object') ? context : {};

    // Generate growth plan using Gemini AI
    const result = await generateCropGrowthPlan(cropName, soilData || {}, {
      planType: safePlanType,
      location: safeContext.location,
      weather: safeContext.weather,
      season: safeContext.season,
      pakistanDateIso: safeContext.pakistanDate,
    });

    // Return successful response
    res.json({
      success: true,
      cropName: cropName,
      growthPlan: result.growthPlan,
      fallback: result.fallback === true,
      ...(result.warning ? { warning: result.warning } : {}),
      generatedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error("Growth Plan Controller Error:", error);
    res.status(500).json({
      success: false,
      error: error?.message || "An unexpected error occurred while generating growth plan"
    });
  }
};

/**
 * Health check for crop recommendation service
 * GET /api/v1/crop-recommendation/health
 */
export const checkHealth = async (req, res) => {
  try {
    const mlHealth = await cropRecommendationService.checkMLHealth();
    
    return res.status(mlHealth.available ? 200 : 503).json({
      status: mlHealth.available ? 'healthy' : 'degraded',
      backend: 'running',
      ml_service: mlHealth.available ? mlHealth.status : 'unavailable',
      error: mlHealth.error || null,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    return res.status(503).json({
      status: 'error',
      backend: 'running',
      ml_service: 'unavailable',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Get all available crops
 * GET /api/v1/crop-recommendation/crops
 */
export const getAvailableCrops = async (req, res) => {
  try {
    const crops = await cropRecommendationService.getAvailableCrops();
    return res.status(200).json({
      success: true,
      crops,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch crops',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Test ML service with sample data
 * POST /api/v1/crop-recommendation/test
 */
export const testMLService = async (req, res) => {
  try {
    const result = await cropRecommendationService.testMLService();
    return res.status(result.success ? 200 : 500).json(result);
    
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Test failed',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Extract N/P/K/pH + environment values from a lab report image.
 * POST /api/v1/crop-recommendation/extract-lab-report
 * multipart/form-data: image
 */
export const extractLabReport = async (req, res) => {
  try {
    const file = req.file;

    if (!file || !file.buffer) {
      return res.status(400).json({
        success: false,
        error: 'Image file is required (field: image)'
      });
    }

    const extracted = await extractLabReportValuesFromImage({
      buffer: file.buffer,
      mimeType: file.mimetype || 'image/jpeg',
      filename: file.originalname,
    });

    if (extracted?.error) {
      return res.status(400).json({
        success: false,
        error: extracted.error,
        extracted: extracted
      });
    }

    return res.status(200).json({
      success: true,
      extracted,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Lab Report Extraction Error:', error);
    const status = error.statusCode || 500;
    return res.status(status).json({
      success: false,
      error: error.message || 'Failed to extract lab report values',
      ...(error.details && { details: error.details }),
      timestamp: new Date().toISOString(),
    });
  }
};

/**
 * Weather-based crop recommendation using live/manual location.
 * POST /api/v1/crop-recommendation/weather-based
 * body: { lat: number, lng: number, locationLabel?: string }
 */
export const recommendWeatherBasedCrops = async (req, res, next) => {
  try {
    const { lat, lng, locationLabel } = req.body || {};

    if (lat === undefined || lng === undefined) {
      return res.status(400).json({
        success: false,
        error: 'lat and lng are required',
      });
    }

    const result = await getWeatherBasedCropRecommendation({
      lat,
      lng,
      locationLabel,
    });

    return res.status(200).json(result);
  } catch (error) {
    console.error('Weather-based Recommendation Error:', error);
    return next(error);
  }
};