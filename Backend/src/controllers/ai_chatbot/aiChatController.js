import AIChat from "../../models/ai_chatbot/aiChat.js";
import AIMessage from "../../models/ai_chatbot/aiMessage.js";
import { askGemini } from "../../services/ai_chatbot/geminiService.js";

const getUserId = (req) => req.user?._id?.toString();

const assertChatOwner = async (chatId, userId) => {
  const chat = await AIChat.findById(chatId);
  if (!chat) return { ok: false, status: 404, error: "Chat not found" };
  if (chat.userId.toString() !== userId) {
    return { ok: false, status: 403, error: "Access denied" };
  }
  return { ok: true, chat };
};

// Create NEW chat
export const createChat = async (req, res) => {
  try {
    const { title } = req.body;
    const userId = getUserId(req);

    if (!title || typeof title !== "string") {
      return res.status(400).json({
        success: false,
        error: "Title is required",
      });
    }

    const chat = await AIChat.create({ title: title.trim(), userId });
    res.json({ success: true, chat });
  } catch (err) {
    console.error("Create chat error:", err);
    res.status(500).json({
      success: false,
      error: "Failed to create chat",
    });
  }
};

// Get ALL chats for authenticated user
export const getAllChats = async (req, res) => {
  try {
    const userId = getUserId(req);
    const chats = await AIChat.find({ userId }).sort({ updatedAt: -1 });
    res.json({ success: true, chats });
  } catch (err) {
    console.error("Get chats error:", err);
    res.status(500).json({
      success: false,
      error: "Failed to fetch chats",
    });
  }
};

// Get chat messages
export const getMessages = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = getUserId(req);

    if (!chatId) {
      return res.status(400).json({
        success: false,
        error: "Chat ID is required",
      });
    }

    const ownership = await assertChatOwner(chatId, userId);
    if (!ownership.ok) {
      return res.status(ownership.status).json({
        success: false,
        error: ownership.error,
      });
    }

    const messages = await AIMessage.find({ chatId }).sort({ createdAt: 1 });
    res.json({ success: true, messages });
  } catch (err) {
    console.error("Get messages error:", err);
    res.status(500).json({
      success: false,
      error: "Failed to fetch messages",
    });
  }
};

// Send message (User → Gemini → Save both)
export const sendMessage = async (req, res) => {
  try {
    const { chatId, message } = req.body;
    const userId = getUserId(req);

    if (!chatId || !message) {
      return res.status(400).json({
        success: false,
        error: "Chat ID and message are required",
      });
    }

    if (typeof message !== "string" || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: "Message must be a non-empty string",
      });
    }

    const ownership = await assertChatOwner(chatId, userId);
    if (!ownership.ok) {
      return res.status(ownership.status).json({
        success: false,
        error: ownership.error,
      });
    }

    const userMessage = await AIMessage.create({
      chatId,
      sender: "user",
      message: message.trim(),
    });

    const history = await AIMessage.find({ chatId })
      .sort({ createdAt: -1 })
      .limit(10)
      .lean();

    const conversationHistory = history.reverse();
    const result = await askGemini(message.trim(), conversationHistory);

    if (!result.success) {
      return res.status(500).json({
        success: false,
        error: result.error,
        userMessage,
      });
    }

    const botMessage = await AIMessage.create({
      chatId,
      sender: "bot",
      message: result.response,
    });

    await AIChat.findByIdAndUpdate(chatId, {
      updatedAt: new Date(),
    });

    res.json({
      success: true,
      userMessage,
      botMessage,
    });
  } catch (err) {
    console.error("Send message error:", err);
    res.status(500).json({
      success: false,
      error: "Failed to send message",
    });
  }
};

// Delete a chat and all its messages
export const deleteChat = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = getUserId(req);

    if (!chatId) {
      return res.status(400).json({
        success: false,
        error: "Chat ID is required",
      });
    }

    const ownership = await assertChatOwner(chatId, userId);
    if (!ownership.ok) {
      return res.status(ownership.status).json({
        success: false,
        error: ownership.error,
      });
    }

    await AIMessage.deleteMany({ chatId });
    await AIChat.findByIdAndDelete(chatId);

    res.json({
      success: true,
      message: "Chat deleted successfully",
    });
  } catch (err) {
    console.error("Delete chat error:", err);
    res.status(500).json({
      success: false,
      error: "Failed to delete chat",
    });
  }
};
