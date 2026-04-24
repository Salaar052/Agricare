// ============================================
// FILE: controllers/aiChatController.js
// ============================================
import AIChat from "../../models/ai_chatbot/aiChat.js";
import AIMessage from "../../models/ai_chatbot/aiMessage.js";
import { askGemini } from "../../services/ai_chatbot/geminiService.js";

// Create NEW chat
export const createChat = async (req, res) => {
  try {
    const { title } = req.body;

    if (!title || typeof title !== "string") {
      return res.status(400).json({ 
        success: false, 
        error: "Title is required" 
      });
    }

    const chat = await AIChat.create({ title });
    res.json({ success: true, chat });
  } catch (err) {
    console.error("Create chat error:", err);
    res.status(500).json({ 
      success: false, 
      error: "Failed to create chat" 
    });
  }
};

// Get ALL chats
export const getAllChats = async (req, res) => {
  try {
    const chats = await AIChat.find().sort({ createdAt: -1 });
    res.json({ success: true, chats });
  } catch (err) {
    console.error("Get chats error:", err);
    res.status(500).json({ 
      success: false, 
      error: "Failed to fetch chats" 
    });
  }
};

// Get chat messages
export const getMessages = async (req, res) => {
  try {
    const { chatId } = req.params;

    if (!chatId) {
      return res.status(400).json({ 
        success: false, 
        error: "Chat ID is required" 
      });
    }

    const messages = await AIMessage.find({ chatId }).sort({ createdAt: 1 });
    res.json({ success: true, messages });
  } catch (err) {
    console.error("Get messages error:", err);
    res.status(500).json({ 
      success: false, 
      error: "Failed to fetch messages" 
    });
  }
};

// Send message (User → Gemini → Save both)
export const sendMessage = async (req, res) => {
  try {
    const { chatId, message } = req.body;

    // Validation
    if (!chatId || !message) {
      return res.status(400).json({ 
        success: false, 
        error: "Chat ID and message are required" 
      });
    }

    if (typeof message !== "string" || message.trim().length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: "Message must be a non-empty string" 
      });
    }

    // Check if chat exists
    const chatExists = await AIChat.findById(chatId);
    if (!chatExists) {
      return res.status(404).json({ 
        success: false, 
        error: "Chat not found" 
      });
    }

    // Save user message
    const userMessage = await AIMessage.create({
      chatId,
      sender: "user",
      message: message.trim()
    });

    // Get conversation history for context (last 10 messages)
    const history = await AIMessage.find({ chatId })
      .sort({ createdAt: -1 })
      .limit(10)
      .lean();
    
    // Reverse to get chronological order
    const conversationHistory = history.reverse();

    // Ask Gemini with context
    const result = await askGemini(message.trim(), conversationHistory);

    // Handle API failure
    if (!result.success) {
      return res.status(500).json({
        success: false,
        error: result.error,
        userMessage // Return user message even if bot fails
      });
    }

    // Save bot reply
    const botMessage = await AIMessage.create({
      chatId,
      sender: "bot",
      message: result.response
    });

    // Update chat's last activity
    await AIChat.findByIdAndUpdate(chatId, { 
      updatedAt: new Date() 
    });

    res.json({
      success: true,
      userMessage,
      botMessage
    });

  } catch (err) {
    console.error("Send message error:", err);
    res.status(500).json({ 
      success: false, 
      error: "Failed to send message" 
    });
  }
};

// Delete a chat and all its messages
export const deleteChat = async (req, res) => {
  try {
    const { chatId } = req.params;

    if (!chatId) {
      return res.status(400).json({ 
        success: false, 
        error: "Chat ID is required" 
      });
    }

    // Delete all messages in the chat
    await AIMessage.deleteMany({ chatId });

    // Delete the chat
    const deletedChat = await AIChat.findByIdAndDelete(chatId);

    if (!deletedChat) {
      return res.status(404).json({ 
        success: false, 
        error: "Chat not found" 
      });
    }

    res.json({ 
      success: true, 
      message: "Chat deleted successfully" 
    });
  } catch (err) {
    console.error("Delete chat error:", err);
    res.status(500).json({ 
      success: false, 
      error: "Failed to delete chat" 
    });
  }
};