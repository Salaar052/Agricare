// File: src/routes/cropRecommendation.routes.js

import { Router } from 'express';
import {
  recommendCrop,
  checkHealth,
  getGrowthPlan,
  getAvailableCrops,
  testMLService
} from '../controllers/cropRecommendation.controller.js';

const router = Router();

/**
 * @route   POST /api/v1/crop-recommendation/recommend
 * @desc    Get crop recommendation based on soil data
 * @access  Public (add auth middleware if needed)
 * @body    { N, P, K, temperature, humidity, ph, rainfall }
 */
router.post('/recommend', recommendCrop);
router.post('/growth-plan', getGrowthPlan);

/**
 * @route   GET /api/v1/crop-recommendation/health
 * @desc    Check health of crop recommendation service and ML model
 * @access  Public
 */
router.get('/health', checkHealth);

/**
 * @route   GET /api/v1/crop-recommendation/crops
 * @desc    Get list of all available crops
 * @access  Public
 */
router.get('/crops', getAvailableCrops);

/**
 * @route   POST /api/v1/crop-recommendation/test
 * @desc    Test ML service with sample data
 * @access  Public (consider restricting to admin)
 */
router.post('/test', testMLService);

export default router;