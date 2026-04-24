// ============================================
// FILE 1: services/crop_recommendation/geminiCropService.js
// ============================================

import axios from "axios";

/**
 * Generate detailed crop growth plan using Gemini AI
 * @param {string} cropName - Name of the recommended crop
 * @param {Object} soilData - Soil and environmental parameters
 * @returns {Object} - {success: boolean, growthPlan?: Object, error?: string}
 */
export async function generateCropGrowthPlan(cropName, soilData) {
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

    // Build comprehensive prompt for detailed growth plan
    const prompt = `You are an expert agricultural consultant. Generate a detailed, professional crop growth plan for ${cropName.toUpperCase()}.

SOIL & ENVIRONMENTAL CONDITIONS:
- Nitrogen (N): ${soilData.N || 'N/A'} kg/ha
- Phosphorus (P): ${soilData.P || 'N/A'} kg/ha
- Potassium (K): ${soilData.K || 'N/A'} kg/ha
- pH Level: ${soilData.ph || 'N/A'}
- Temperature: ${soilData.temperature || 'N/A'}°C
- Humidity: ${soilData.humidity || 'N/A'}%
- Rainfall: ${soilData.rainfall || 'N/A'} mm

Provide a comprehensive growth plan in the following JSON format (respond ONLY with valid JSON, no markdown):

{
  "cropName": "${cropName}",
  "overview": {
    "description": "Brief crop description (2-3 sentences)",
    "totalGrowthPeriod": "X-Y months",
    "difficulty": "Easy/Medium/Hard",
    "bestSeason": "Season name"
  },
  "growthStages": [
    {
      "stage": "Stage name",
      "duration": "X-Y days/weeks",
      "description": "What happens in this stage",
      "keyActivities": ["Activity 1", "Activity 2", "Activity 3"]
    }
  ],
  "irrigationPlan": {
    "frequency": "How often to irrigate",
    "method": "Best irrigation method",
    "waterRequirement": "Amount needed",
    "criticalPeriods": ["Period 1", "Period 2"],
    "tips": ["Tip 1", "Tip 2", "Tip 3"]
  },
  "fertilizationPlan": {
    "basalApplication": {
      "nitrogen": "Amount and timing",
      "phosphorus": "Amount and timing",
      "potassium": "Amount and timing"
    },
    "topDressing": [
      {
        "stage": "When to apply",
        "nutrients": "What to apply",
        "amount": "How much"
      }
    ],
    "organicOptions": ["Option 1", "Option 2"]
  },
  "pestAndDiseaseManagement": {
    "commonPests": [
      {
        "name": "Pest name",
        "symptoms": "How to identify",
        "prevention": "Preventive measures",
        "treatment": "Treatment options"
      }
    ],
    "commonDiseases": [
      {
        "name": "Disease name",
        "symptoms": "How to identify",
        "prevention": "Preventive measures",
        "treatment": "Treatment options"
      }
    ],
    "organicSolutions": ["Solution 1", "Solution 2"]
  },
  "soilManagement": {
    "preparation": ["Step 1", "Step 2", "Step 3"],
    "maintenance": ["Task 1", "Task 2"],
    "phAdjustment": "Recommendations based on current pH",
    "organicMatter": "How to improve soil"
  },
  "harvestingGuide": {
    "maturityIndicators": ["Indicator 1", "Indicator 2"],
    "harvestMethod": "How to harvest",
    "postHarvest": ["Step 1", "Step 2"],
    "expectedYield": "Typical yield per hectare",
    "storageAdvice": "How to store"
  },
  "weatherConsiderations": {
    "temperatureManagement": "Advice based on current conditions",
    "humidityManagement": "Advice based on current conditions",
    "rainfallManagement": "Advice based on current conditions",
    "extremeWeatherProtection": ["Protection 1", "Protection 2"]
  },
  "costEstimation": {
    "seedCost": "Estimated range",
    "fertilizerCost": "Estimated range",
    "irrigationCost": "Estimated range",
    "laborCost": "Estimated range",
    "totalEstimated": "Total range",
    "breakEvenPoint": "When to expect break-even"
  },
  "proTips": [
    "Professional tip 1",
    "Professional tip 2",
    "Professional tip 3",
    "Professional tip 4"
  ],
  "warnings": [
    "Warning 1",
    "Warning 2"
  ]
}

IMPORTANT: Respond ONLY with the JSON object. No additional text, no markdown formatting, no code blocks.`;

    // Call Gemini API
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${process.env.GEMINI_API_KEY}`,
      {
        contents: [{
          role: "user",
          parts: [{ text: prompt }]
        }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 8000,
          topP: 0.95,
          topK: 40
        }
      },
      {
        timeout: 60000, // 60 second timeout for detailed response
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

    // Clean response - remove markdown code blocks if present
    botResponse = botResponse.trim();
    botResponse = botResponse.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    botResponse = botResponse.trim();

    // Parse JSON response
    let growthPlan;
    try {
      growthPlan = JSON.parse(botResponse);
    } catch (parseError) {
      console.error("JSON Parse Error:", parseError);
      console.error("Raw Response:", botResponse.substring(0, 500));
      return {
        success: false,
        error: "Failed to parse AI response. Please try again."
      };
    }

    // Validate essential fields
    if (!growthPlan.cropName || !growthPlan.overview || !growthPlan.growthStages) {
      return {
        success: false,
        error: "Incomplete growth plan received. Please try again."
      };
    }

    return {
      success: true,
      growthPlan: growthPlan
    };

  } catch (error) {
    console.error("Gemini Crop Service Error:", error.response?.data || error.message);

    // Handle specific error types
    if (error.response) {
      const errorMessage = error.response.data?.error?.message || "Gemini API request failed";
      return {
        success: false,
        error: errorMessage
      };
    } else if (error.request) {
      return {
        success: false,
        error: "No response from Gemini API. Please check your internet connection."
      };
    } else if (error.code === 'ECONNABORTED') {
      return {
        success: false,
        error: "Request timeout. The AI is taking too long to respond. Please try again."
      };
    } else {
      return {
        success: false,
        error: "Failed to generate growth plan. Please try again."
      };
    }
  }
}

