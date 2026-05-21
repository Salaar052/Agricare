import express from "express";
import {
  createChat,
  getAllChats,
  getMessages,
  sendMessage,
  deleteChat,
} from "../../controllers/ai_chatbot/aiChatController.js";
import { verifyJwt } from "../../middlewares/authentication.js";

const aiChatbotRouter = express.Router();

aiChatbotRouter.use(verifyJwt);

aiChatbotRouter.post("/new", createChat);
aiChatbotRouter.get("/all", getAllChats);
aiChatbotRouter.get("/messages/:chatId", getMessages);
aiChatbotRouter.post("/send", sendMessage);
aiChatbotRouter.delete("/delete/:chatId", deleteChat);

export default aiChatbotRouter;