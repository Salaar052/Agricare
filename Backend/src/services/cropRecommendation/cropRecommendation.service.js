// File: src/services/cropRecommendation.service.js

import axios from 'axios';

/**
 * Crop Recommendation Service
 * Handles all ML model communication for crop predictions
 * Extracted from old AgriCare backend - maintains 100% compatibility
 */

class CropRecommendationService {
  constructor() {
    this.ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:5001';
    console.log(`🤖 ML Service configured at: ${this.ML_SERVICE_URL}`);
  }

  /**
   * Call ML Service for prediction
   * @param {Object} inputData - Soil and environmental data
   * @returns {Promise<Object>} Prediction result
   */
  async callMLService(inputData) {
    try {
      console.log('📤 Calling ML service...');
      console.log('   URL:', `${this.ML_SERVICE_URL}/predict`);
      console.log('   Data:', JSON.stringify(inputData));
      
      const response = await axios.post(
        `${this.ML_SERVICE_URL}/predict`,
        inputData,
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 15000
        }
      );
      
      console.log('✅ ML service responded:', response.data.recommended_crop);
      return response.data;
      
    } catch (error) {
      console.error('❌ ML Service Error:', error.message);
      
      if (error.response) {
        console.error('   Status:', error.response.status);
        console.error('   Data:', error.response.data);
        throw new Error(error.response.data.error || 'ML service returned error');
      }
      
      if (error.code === 'ECONNREFUSED') {
        throw new Error('ML service not running on ' + this.ML_SERVICE_URL);
      }
      
      throw new Error('ML service unavailable: ' + error.message);
    }
  }

  /**
   * Validate input data
   * @param {Object} data - Input data to validate
   * @returns {Object} { valid: boolean, errors: Array, missing: Array }
   */
  validateInput(data) {
    const { N, P, K, temperature, humidity, ph, rainfall } = data;
    
    // Check missing fields
    const missingFields = [];
    if (N === undefined || N === null) missingFields.push('N');
    if (P === undefined || P === null) missingFields.push('P');
    if (K === undefined || K === null) missingFields.push('K');
    if (temperature === undefined || temperature === null) missingFields.push('temperature');
    if (humidity === undefined || humidity === null) missingFields.push('humidity');
    if (ph === undefined || ph === null) missingFields.push('ph');
    if (rainfall === undefined || rainfall === null) missingFields.push('rainfall');
    
    if (missingFields.length > 0) {
      return {
        valid: false,
        missing: missingFields,
        errors: []
      };
    }
    
    // Validate data types and ranges
    const errors = [];
    
    // Check if values are numbers
    if (isNaN(parseFloat(N))) errors.push('N must be a number');
    if (isNaN(parseFloat(P))) errors.push('P must be a number');
    if (isNaN(parseFloat(K))) errors.push('K must be a number');
    if (isNaN(parseFloat(temperature))) errors.push('temperature must be a number');
    if (isNaN(parseFloat(humidity))) errors.push('humidity must be a number');
    if (isNaN(parseFloat(ph))) errors.push('ph must be a number');
    if (isNaN(parseFloat(rainfall))) errors.push('rainfall must be a number');
    
    // Check ranges
    if (!isNaN(N) && parseFloat(N) < 0) {
      errors.push('N must be positive');
    }
    if (!isNaN(P) && parseFloat(P) < 0) {
      errors.push('P must be positive');
    }
    if (!isNaN(K) && parseFloat(K) < 0) {
      errors.push('K must be positive');
    }
    if (!isNaN(humidity)) {
      const hum = parseFloat(humidity);
      if (hum < 0 || hum > 100) {
        errors.push('humidity must be between 0 and 100');
      }
    }
    if (!isNaN(ph)) {
      const phVal = parseFloat(ph);
      if (phVal < 0 || phVal > 14) {
        errors.push('ph must be between 0 and 14');
      }
    }
    if (!isNaN(rainfall) && parseFloat(rainfall) < 0) {
      errors.push('rainfall must be positive');
    }
    
    return {
      valid: errors.length === 0,
      missing: [],
      errors
    };
  }

  /**
   * Prepare data for ML service
   * @param {Object} rawData - Raw input data
   * @returns {Object} Formatted data for ML service
   */
  prepareMLInput(rawData) {
    return {
      N: parseFloat(rawData.N),
      P: parseFloat(rawData.P),
      K: parseFloat(rawData.K),
      temperature: parseFloat(rawData.temperature),
      humidity: parseFloat(rawData.humidity),
      ph: parseFloat(rawData.ph),
      rainfall: parseFloat(rawData.rainfall)
    };
  }

  /**
   * Get crop recommendation
   * Main method that combines validation, ML prediction
   * @param {Object} inputData - User input data
   * @returns {Promise<Object>} Recommendation result
   */
  async getRecommendation(inputData) {
    try {
      console.log('\n' + '='.repeat(60));
      console.log('📥 NEW CROP RECOMMENDATION REQUEST');
      console.log('='.repeat(60));
      console.log('Input:', JSON.stringify(inputData, null, 2));
      
      // Validate input
      const validation = this.validateInput(inputData);
      
      if (!validation.valid) {
        const error = new Error('Validation failed');
        error.statusCode = 400;
        error.details = {
          missing: validation.missing,
          validation_errors: validation.errors
        };
        throw error;
      }
      
      console.log('✅ Validation passed');
      
      // Prepare data for ML service
      const mlInput = this.prepareMLInput(inputData);
      console.log('📊 Prepared data:', mlInput);
      
      // Call ML service
      const prediction = await this.callMLService(mlInput);
      
      // Prepare response
      const response = {
        success: true,
        recommended_crop: prediction.recommended_crop,
        confidence: prediction.confidence,
        all_recommendations: prediction.all_recommendations,
        input_data: mlInput,
        timestamp: new Date().toISOString()
      };
      
      console.log('✅ SUCCESS!');
      console.log('   Crop:', response.recommended_crop);
      console.log('   Confidence:', response.confidence + '%');
      console.log('='.repeat(60) + '\n');
      
      return response;
      
    } catch (error) {
      console.error('❌ ERROR in getRecommendation');
      console.error('   Message:', error.message);
      console.log('='.repeat(60) + '\n');
      throw error;
    }
  }

  /**
   * Check ML service health
   * @returns {Promise<Object>} Health status
   */
  async checkMLHealth() {
    try {
      const response = await axios.get(`${this.ML_SERVICE_URL}/health`, { 
        timeout: 5000 
      });
      return {
        available: true,
        status: response.data
      };
    } catch (error) {
      return {
        available: false,
        error: error.message
      };
    }
  }

  /**
   * Get all available crops from ML service
   * @returns {Promise<Array>} List of crops
   */
  async getAvailableCrops() {
    try {
      const response = await axios.get(`${this.ML_SERVICE_URL}/crops`, { 
        timeout: 5000 
      });
      return response.data;
    } catch (error) {
      throw new Error('Failed to fetch crops: ' + error.message);
    }
  }

  /**
   * Test ML service with sample data
   * @returns {Promise<Object>} Test result
   */
  async testMLService() {
    console.log('\n🧪 Running ML service test...');
    
    const testData = {
      N: 90,
      P: 42,
      K: 43,
      temperature: 20.879744,
      humidity: 82.002744,
      ph: 6.502985,
      rainfall: 202.935536
    };
    
    try {
      const prediction = await this.callMLService(testData);
      return {
        success: true,
        message: 'Test successful - Expected: rice',
        test_input: testData,
        prediction_result: prediction
      };
    } catch (error) {
      return {
        success: false,
        message: 'Test failed',
        error: error.message
      };
    }
  }
}

// Create singleton instance
const cropRecommendationService = new CropRecommendationService();

export default cropRecommendationService;