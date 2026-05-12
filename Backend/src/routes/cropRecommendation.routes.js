// File: src/routes/cropRecommendation.routes.js

import { Router } from 'express';
import multer from 'multer';
import {
  recommendCrop,
  checkHealth,
  getGrowthPlan,
  getAvailableCrops,
  testMLService,
  extractLabReport,
  recommendWeatherBasedCrops
} from '../controllers/cropRecommendation.controller.js';

const router = Router();

// In-memory upload for lab-report scanning (no Cloudinary needed)
const labReportUpload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (req, file, cb) => {
    const allowedExts = new Set(['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif']);
    const name = (file.originalname || '').toLowerCase();
    const dot = name.lastIndexOf('.');
    const ext = dot >= 0 ? name.slice(dot) : '';

    if (typeof file.mimetype === 'string' && file.mimetype.startsWith('image/')) {
      return cb(null, true);
    }

    // Dart/Flutter multipart defaults to application/octet-stream unless explicit contentType is set.
    if (file.mimetype === 'application/octet-stream' && allowedExts.has(ext)) {
      return cb(null, true);
    }

    return cb(new Error('Invalid file type. Please upload an image.'));
  },
});

/**
 * @route   POST /api/v1/crop-recommendation/recommend
 * @desc    Get crop recommendation based on soil data
 * @access  Public (add auth middleware if needed)
 * @body    { N, P, K, temperature, humidity, ph, rainfall }
 */
router.post('/recommend', recommendCrop);
router.post('/growth-plan', getGrowthPlan);
router.post('/weather-based', recommendWeatherBasedCrops);

/**
 * @route   POST /api/v1/crop-recommendation/extract-lab-report
 * @desc    Extract N,P,K,pH,temperature,humidity,rainfall from a lab-report image
 * @access  Public (requires GEMINI_API_KEY on backend)
 * @form    multipart/form-data (field: image)
 */
router.post('/extract-lab-report', labReportUpload.single('image'), extractLabReport);

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