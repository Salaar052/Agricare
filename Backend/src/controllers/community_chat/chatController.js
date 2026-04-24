import ChatRoom from "../../models/community_chat/ChatRoom.js";
import Message from "../../models/community_chat/Message.js";
import User from "../../models/auth/user.js";

// Create room with image (public only)
export const createRoom = async (req, res) => {
   console.log("create room hit")
  try {
   
    const { name } = req.body;
    const userId = req.user._id.toString();

    const roomData = {
      name,
      isPublic: true,
      admin: userId,
      members: [userId],
    };

    // 🔥 Save Cloudinary URL of room image
    if (req.file) {
      roomData.image = req.file.path;
    }

    const room = await ChatRoom.create(roomData);
    res.json(room);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get all public rooms
export const getRooms = async (req, res) => {
  try {
    const userId = req.user._id.toString(); // Get from authenticated user

    // Get all public rooms
    const rooms = await ChatRoom.find({ isPublic: true }).select('-__v');
    
    // Add member count and membership status to each room
    const roomsWithInfo = rooms.map(room => ({
      ...room.toObject(),
      memberCount: room.members.length,
      isMember: room.members.includes(userId)
    }));

    res.json(roomsWithInfo);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get rooms user has joined
export const getMyRooms = async (req, res) => {
  try {
    const userId = req.user._id.toString(); // Get from authenticated user

    // Get rooms where user is a member
    const rooms = await ChatRoom.find({ 
      members: userId 
    }).select('-__v');
    
    // Add member count to each room
    const roomsWithCount = rooms.map(room => ({
      ...room.toObject(),
      memberCount: room.members.length,
      isCreator: room.admin === userId
    }));

    res.json(roomsWithCount);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get room members
export const getRoomMembers = async (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user._id.toString(); // Get from authenticated user

    const room = await ChatRoom.findById(roomId);
    
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    // Check if user is a member of the room
    if (!room.members.includes(userId)) {
      return res.status(403).json({ error: "You must be a member to view members" });
    }

    res.json({ 
      members: room.members, 
      memberCount: room.members.length,
      admin: room.admin
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Delete room (creator only)
export const deleteRoom = async (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user._id.toString(); // Get from authenticated user

    const room = await ChatRoom.findById(roomId);
    
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    // Only room creator can delete
    if (room.admin !== userId) {
      return res.status(403).json({ error: "Only room creator can delete this room" });
    }

    // Delete all messages in the room
    await Message.deleteMany({ roomId });
    
    // Delete the room
    await ChatRoom.findByIdAndDelete(roomId);

    res.json({ message: "Room deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Join room
export const joinRoom = async (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user._id.toString(); // Get from authenticated user

    const room = await ChatRoom.findById(roomId);
    
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    if (!room.isPublic) {
      return res.status(403).json({ error: "Cannot join private room" });
    }

    if (room.members.includes(userId)) {
      return res.status(400).json({ error: "Already a member of this room" });
    }

    room.members.push(userId);
    await room.save();

    res.json({ message: "Joined room successfully", room });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Leave room
export const leaveRoom = async (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user._id.toString(); // Get from authenticated user

    const room = await ChatRoom.findById(roomId);
    
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    // Room creator cannot leave (must delete room instead)
    if (room.admin === userId) {
      return res.status(400).json({ 
        error: "Room creator cannot leave. Delete the room instead." 
      });
    }

    if (!room.members.includes(userId)) {
      return res.status(400).json({ error: "You are not a member of this room" });
    }

    room.members = room.members.filter(member => member !== userId);
    await room.save();

    res.json({ message: "Left room successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Search rooms
export const searchRooms = async (req, res) => {
  try {
    const { query } = req.query;
    const userId = req.user._id.toString(); // Get from authenticated user

    if (!query || query.trim() === '') {
      return res.status(400).json({ error: "Search query is required" });
    }

    // Search in public rooms only
    const searchQuery = {
      $and: [
        { $text: { $search: query } },
        { isPublic: true }
      ]
    };

    const rooms = await ChatRoom.find(searchQuery).select('-__v');
    
    const roomsWithInfo = rooms.map(room => ({
      ...room.toObject(),
      memberCount: room.members.length,
      isMember: room.members.includes(userId)
    }));

    res.json(roomsWithInfo);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get messages of a room
export const getMessages = async (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user._id.toString(); // Get from authenticated user

    // Check if room exists and user is member
    const room = await ChatRoom.findById(roomId);
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    if (!room.members.includes(userId)) {
      return res.status(403).json({ error: "You must join this room to view messages" });
    }

    const messages = await Message.find({ roomId })
      .sort({ createdAt: 1 });
    
    res.json(messages);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Send message
export const sendMessage = async (req, res) => {
  try {
    const { roomId } = req.params;
    const { message } = req.body;
    const userId = req.user._id.toString();

    if (!message || message.trim() === '') {
      return res.status(400).json({ error: "Message cannot be empty" });
    }

    // Check if user is member
    const room = await ChatRoom.findById(roomId);
    if (!room) return res.status(404).json({ error: "Room not found" });
    if (!room.members.includes(userId)) return res.status(403).json({ error: "You must join this room to send messages" });

    // Fetch username from DB
    const user = await User.findById(userId);
    const senderName = user ? user.username : "Unknown";

    const newMessage = await Message.create({
      roomId,
      sender: userId,
      senderName,
      message,
      readBy: [userId]
    });

    res.json(newMessage);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};


// File upload message
export const uploadFile = async (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user._id.toString();

    if (!req.file) return res.status(400).json({ error: "No file uploaded" });

    const room = await ChatRoom.findById(roomId);
    if (!room) return res.status(404).json({ error: "Room not found" });
    if (!room.members.includes(userId)) return res.status(403).json({ error: "You must join this room to upload files" });

    // Fetch username from DB
    const user = await User.findById(userId);
    const senderName = user ? user.username : "Unknown";

    const saved = await Message.create({
      roomId,
      sender: userId,
      senderName,
      fileUrl: req.file.path,
      readBy: [userId],
    });

    res.json(saved);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get unread message count
export const getUnreadCount = async (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user._id.toString(); // Get from authenticated user

    // Check if user is member
    const room = await ChatRoom.findById(roomId);
    if (!room || !room.members.includes(userId)) {
      return res.status(403).json({ error: "Access denied" });
    }

    const unreadCount = await Message.countDocuments({
      roomId,
      readBy: { $ne: userId }
    });

    res.json({ unreadCount });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Mark messages as read
export const markAsRead = async (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user._id.toString(); // Get from authenticated user

    // Check if user is member
    const room = await ChatRoom.findById(roomId);
    if (!room || !room.members.includes(userId)) {
      return res.status(403).json({ error: "Access denied" });
    }

    await Message.updateMany(
      { 
        roomId, 
        readBy: { $ne: userId } 
      },
      { 
        $push: { readBy: userId } 
      }
    );

    res.json({ message: "Messages marked as read" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Delete message (sender or admin only)
export const deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user._id.toString();

    const message = await Message.findById(messageId);
    
    if (!message) {
      return res.status(404).json({ error: "Message not found" });
    }

    // Get the room to check if user is admin
    const room = await ChatRoom.findById(message.roomId);
    
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    // Check if user is sender or room admin
    if (message.sender !== userId && room.admin !== userId) {
      return res.status(403).json({ error: "Not authorized to delete this message" });
    }

    await Message.findByIdAndDelete(messageId);
    
    res.json({ message: "Message deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};