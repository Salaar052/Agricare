// ============================================
// FILE: src/sockets/chatSocket.js
// ============================================
import Message from "../models/community_chat/Message.js";
import User from "../models/auth/user.js"; // import your User model

export default function setupChatSocket(io) {
  io.on("connection", (socket) => {
    console.log("✅ User connected:", socket.id);

    // Join Room
    socket.on("joinRoom", (roomId) => {
      socket.join(roomId);
      console.log(`📥 Socket ${socket.id} joined room ${roomId}`);
    });

    // Send Message
    socket.on("sendMessage", async (data) => {
      try {
        console.log("📨 New message:", data);

        // Fetch username from DB
        const user = await User.findById(data.sender);
        const senderName = user ? user.username : "Unknown";

        const newMsg = await Message.create({
          roomId: data.roomId,
          sender: data.sender,
          senderName, // now fetched from DB
          message: data.message,
          readBy: [data.sender]
        });

        // Emit to all clients in the room
        io.to(data.roomId).emit("newMessage", newMsg);

        console.log("✅ Message sent to room:", data.roomId);
      } catch (error) {
        console.error("❌ Error sending message:", error);
        socket.emit("messageError", {
          error: "Failed to send message",
          details: error.message
        });
      }
    });

    // Delete Message
    socket.on("deleteMessage", async (data) => {
      try {
        const { roomId, messageId } = data;

        // Broadcast deletion to all clients in the room
        io.to(roomId).emit("messageDeleted", { messageId });
      } catch (error) {
        console.error("Error deleting message:", error);
      }
    });

    // Typing indicator
    socket.on("typing", (data) => {
      socket.to(data.roomId).emit("userTyping", {
        userId: data.userId,
        username: data.username
      });
    });

    socket.on("stopTyping", (data) => {
      socket.to(data.roomId).emit("userStoppedTyping", {
        userId: data.userId
      });
    });

    // Leave Room
    socket.on("leaveRoom", (roomId) => {
      socket.leave(roomId);
      console.log(`📤 Socket ${socket.id} left room ${roomId}`);
    });

    // Disconnect
    socket.on("disconnect", () => {
      console.log("❌ User disconnected:", socket.id);
    });

    // Error handling
    socket.on("error", (error) => {
      console.error("💥 Socket error:", error);
    });
  });
}
