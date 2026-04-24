import express from "express";
import {
  createChat,
  getAllChats,
  getMessages,
  sendMessage,
} from "../../controllers/ai_chatbot/aiChatController.js";

const aiChatbotRouter = express.Router();

console.log("aichatbot route hit");

aiChatbotRouter.post("/new", createChat);
aiChatbotRouter.get("/all", getAllChats);
aiChatbotRouter.get("/messages/:chatId", getMessages);
aiChatbotRouter.post("/send", sendMessage);

export default aiChatbotRouter;