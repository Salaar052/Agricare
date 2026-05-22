import axios from "axios";

export const AGRICARE_CONTEXT = `
You are an AI assistant inside a platform called "AgriCare".

AgriCare is an AI-powered agriculture advisory system designed to help farmers make better decisions using data, technology, and expert guidance.

Your responsibilities include:
- Providing crop recommendations based on soil conditions, weather, and location
- Suggesting fertilizers and pesticides with proper usage guidance
- Helping farmers diagnose plant diseases and issues
- Offering weather-based farming advice
- Giving market insights and crop profitability suggestions
- Assisting with home gardening tips for beginners and small-scale growers

STRICT RULES:
- Only answer agriculture-related questions
- If question is unrelated, reply:
"I can only help with agriculture-related questions."

- Keep answers simple, practical, and farmer-friendly
- Avoid complex technical language
- Do not answer coding, politics, general knowledge, or unrelated topics

Tone:
- Friendly and expert-like
- Practical farming advice only
`;

/**
 * Ask Gemini AI with conversation history
 * @param {string} prompt - Current user message
 * @param {Array} conversationHistory - [{sender, message}]
 * @returns {Object}
 */
export async function askGemini(prompt, conversationHistory = []) {
  try {
    if (!process.env.GEMINI_API_KEY) {
      return {
        success: false,
        error: "Gemini API key is not configured",
      };
    }

    const contents = [];

    contents.push({
      role: "user",
      parts: [{ text: AGRICARE_CONTEXT }],
    });

    if (conversationHistory && conversationHistory.length > 0) {
      conversationHistory.forEach((msg) => {
        contents.push({
          role: msg.sender === "user" ? "user" : "model",
          parts: [{ text: msg.message }],
        });
      });
    }

    contents.push({
      role: "user",
      parts: [{ text: prompt }],
    });

    const res = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${process.env.GEMINI_API_KEY}`,
      { contents },
      {
        timeout: 30000,
        headers: { "Content-Type": "application/json" },
      }
    );

    const botResponse =
      res.data?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!botResponse) {
      return { success: false, error: "No response from Gemini AI" };
    }

    return { success: true, response: botResponse };
  } catch (error) {
    console.error("Gemini API Error:", error.response?.data || error.message);

    if (error.response) {
      return {
        success: false,
        error:
          error.response.data?.error?.message ||
          "Gemini API request failed",
      };
    }
    if (error.request) {
      return { success: false, error: "No response from Gemini API" };
    }
    if (error.code === "ECONNABORTED") {
      return { success: false, error: "Request timeout. Please try again." };
    }
    return { success: false, error: "Failed to communicate with Gemini AI" };
  }
}
