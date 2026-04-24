import express from "express";
import { uploadRoomImage, uploadChatFile } from "../../utils/cloudinary.js";
import { verifyJwt } from "../../middlewares/authentication.js";
import {
  createRoom,
  getRooms,
  getMyRooms,
  getMessages,
  uploadFile,
  joinRoom,
  leaveRoom,
  sendMessage,
  getUnreadCount,
  markAsRead,
  deleteRoom,
  getRoomMembers,
  searchRooms,
  deleteMessage  // ADD THIS
} from "../../controllers/community_chat/chatController.js";

const router = express.Router();

// Apply authentication middleware to ALL routes
router.use(verifyJwt);

// Room management
router.post("/room", uploadRoomImage.single("image"), createRoom);
router.get("/rooms", getRooms);
router.get("/my-rooms", getMyRooms);
router.get("/room/:roomId/members", getRoomMembers);
router.delete("/room/:roomId", deleteRoom);
router.post("/room/:roomId/join", joinRoom);
router.post("/room/:roomId/leave", leaveRoom);
router.get("/rooms/search", searchRooms);

// Message management
router.get("/messages/:roomId", getMessages);
router.post("/message/:roomId", sendMessage);
router.post("/upload/:roomId", uploadChatFile.single("file"), uploadFile);
router.delete("/message/:messageId", deleteMessage); // ADD THIS LINE

// Read status
router.get("/unread/:roomId", getUnreadCount);
router.post("/read/:roomId", markAsRead);

export default router;