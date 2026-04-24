import axios from "axios";

/**
 * Ask Gemini AI with conversation history
 * @param {string} prompt - Current user message (for fallback if no history provided)
 * @param {Array} conversationHistory - Array of previous messages INCLUDING current user message [{sender, message, createdAt}]
 * @returns {Object} - {success: boolean, response?: string, error?: string}
 */
export async function askGemini(prompt, conversationHistory = []) {
  try {
    // Validate API key
    if (!process.env.GEMINI_API_KEY) {
      return {
        success: false,
        error: "Gemini API key is not configured"
      };
    }

    // Build conversation context for Gemini
    const contents = [];

    // Add conversation history (if any)
    // The controller already includes the current user message in the history
    if (conversationHistory && conversationHistory.length > 0) {
      conversationHistory.forEach(msg => {
        contents.push({
          role: msg.sender === "user" ? "user" : "model",
          parts: [{ text: msg.message }]
        });
      });
    } else {
      // Fallback: if no history provided, use the prompt directly
      contents.push({
        role: "user",
        parts: [{ text: prompt }]
      });
    }

    // Call Gemini API
    const res = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${process.env.GEMINI_API_KEY}`,
      {
        contents: contents
      },
      {
        timeout: 30000, // 30 second timeout
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    // Extract response
    const botResponse = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!botResponse) {
      return {
        success: false,
        error: "No response from Gemini AI"
      };
    }

    return {
      success: true,
      response: botResponse
    };

  } catch (error) {
    console.error("Gemini API Error:", error.response?.data || error.message);

    // Handle specific error types
    if (error.response) {
      // API returned an error response
      const errorMessage = error.response.data?.error?.message || "Gemini API request failed";
      return {
        success: false,
        error: errorMessage
      };
    } else if (error.request) {
      // Request made but no response
      return {
        success: false,
        error: "No response from Gemini API. Please check your internet connection."
      };
    } else if (error.code === 'ECONNABORTED') {
      // Timeout
      return {
        success: false,
        error: "Request timeout. Please try again."
      };
    } else {
      // Something else went wrong
      return {
        success: false,
        error: "Failed to communicate with Gemini AI"
      };
    }
  }
}