// File: src/controllers/cropRecommendation.controller.js

import cropRecommendationService from '../services/cropRecommendation/cropRecommendation.service.js';
import { generateCropGrowthPlan } from '../services/cropRecommendation/geminiCropService.js';
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
    const { cropName, soilData } = req.body;

    // Validation
    if (!cropName || typeof cropName !== 'string') {
      return res.status(400).json({
        success: false,
        error: "Crop name is required and must be a string"
      });
    }

    if (!soilData || typeof soilData !== 'object') {
      return res.status(400).json({
        success: false,
        error: "Soil data is required and must be an object"
      });
    }

    // Validate required soil parameters
    const requiredParams = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall'];
    const missingParams = requiredParams.filter(param => soilData[param] === undefined);
    
    if (missingParams.length > 0) {
      return res.status(400).json({
        success: false,
        error: `Missing required soil parameters: ${missingParams.join(', ')}`
      });
    }

    // Validate numeric values
    for (const param of requiredParams) {
      if (typeof soilData[param] !== 'number' || isNaN(soilData[param])) {
        return res.status(400).json({
          success: false,
          error: `${param} must be a valid number`
        });
      }
    }

    // Generate growth plan using Gemini AI
    const result = await generateCropGrowthPlan(cropName, soilData);

    if (!result.success) {
      return res.status(500).json({
        success: false,
        error: result.error || "Failed to generate growth plan"
      });
    }

    // Return successful response
    res.json({
      success: true,
      cropName: cropName,
      growthPlan: result.growthPlan,
      generatedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error("Growth Plan Controller Error:", error);
    res.status(500).json({
      success: false,
      error: "An unexpected error occurred while generating growth plan"
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