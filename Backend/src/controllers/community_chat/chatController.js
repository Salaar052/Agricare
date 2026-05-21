import ChatRoom from "../../models/community_chat/ChatRoom.js";
import Message from "../../models/community_chat/Message.js";
import User from "../../models/auth/user.js";
import {
  uploadChatFileToCloudinary,
  uploadRoomToCloudinary,
} from "../../utils/cloudinary.js";

const isAdminUser = (user) => {
  if (!user) return false;
  if (user.isAdmin === true) return true;
  if (typeof user.role === "string" && user.role.toLowerCase() === "admin") {
    return true;
  }
  return false;
};

const ensureAdmin = (req, res) => {
  if (!isAdminUser(req.user)) {
    res.status(403).json({ error: "Admin access required" });
    return false;
  }
  return true;
};

// Create room with image (public only)
export const createRoom = async (req, res) => {
  try {
    const { name } = req.body;
    const userId = req.user._id.toString();

    if (!name || !String(name).trim()) {
      return res.status(400).json({ error: "Group name is required" });
    }

    const roomData = {
      name: String(name).trim(),
      isPublic: true,
      admin: userId,
      members: [userId],
    };

    if (req.file) {
      const imageUrl = await uploadRoomToCloudinary(req.file);
      if (imageUrl) roomData.image = imageUrl;
    }

    const room = await ChatRoom.create(roomData);
    res.status(201).json({
      ...room.toObject(),
      memberCount: 1,
      isCreator: true,
      isMember: true,
    });
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

    const memberUsers = await User.find({ _id: { $in: room.members } }).select(
      "username profileImage"
    );
    const adminUser = await User.findById(room.admin).select("username profileImage");

    res.json({
      members: memberUsers.map((u) => ({
        id: u._id.toString(),
        username: u.username,
        profileImage: u.profileImage || null,
      })),
      memberCount: room.members.length,
      admin: {
        id: room.admin,
        username: adminUser?.username || "Unknown",
        profileImage: adminUser?.profileImage || null,
      },
      room: {
        id: room._id.toString(),
        name: room.name,
        image: room.image || null,
        createdAt: room.createdAt,
      },
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

    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    const room = await ChatRoom.findById(roomId);
    if (!room) return res.status(404).json({ error: "Room not found" });

    if (!room.members.includes(userId)) {
      return res.status(403).json({ error: "Not a member" });
    }

    const user = await User.findById(userId);

    const fileUrl = await uploadChatFileToCloudinary(req.file);

    const saved = await Message.create({
      roomId,
      sender: userId,
      senderName: user?.username || "Unknown",
      fileUrl,
      readBy: [userId],
    });

    const io = req.app.get("io");
    if (io) {
      const payload =
        typeof saved.toObject === "function"
          ? saved.toObject({ flattenMaps: true })
          : saved;
      io.to(String(roomId)).emit("newMessage", payload);
    }

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

    // Check if user is sender, room admin, or a site admin
    if (
      message.sender !== userId &&
      room.admin !== userId &&
      !isAdminUser(req.user)
    ) {
      return res.status(403).json({ error: "Not authorized to delete this message" });
    }

    await Message.findByIdAndDelete(messageId);
    
    res.json({ message: "Message deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Admin: list all chat rooms
export const adminGetAllRooms = async (req, res) => {
  try {
    if (!ensureAdmin(req, res)) return;

    const rooms = await ChatRoom.find({})
      .sort({ createdAt: -1 })
      .select("-__v");

    const roomSummaries = await Promise.all(
      rooms.map(async (room) => {
        const adminUser = await User.findById(room.admin).select("username email");
        return {
          ...room.toObject(),
          memberCount: room.members.length,
          adminUser: adminUser
            ? {
                _id: adminUser._id,
                username: adminUser.username || "Unknown",
                email: adminUser.email || "",
              }
            : null,
        };
      })
    );

    res.json(roomSummaries);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Admin: get room messages without joining room
export const adminGetRoomMessages = async (req, res) => {
  try {
    if (!ensureAdmin(req, res)) return;
    const { roomId } = req.params;

    const room = await ChatRoom.findById(roomId);
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    const messages = await Message.find({ roomId }).sort({ createdAt: 1 });
    res.json(messages);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Admin: get room members with user profiles
export const adminGetRoomMembers = async (req, res) => {
  try {
    if (!ensureAdmin(req, res)) return;
    const { roomId } = req.params;

    const room = await ChatRoom.findById(roomId);
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    const users = await User.find({ _id: { $in: room.members } }).select(
      "_id username email profileImage"
    );
    const userMap = new Map(users.map((u) => [u._id.toString(), u]));

    const members = room.members.map((memberId) => {
      const member = userMap.get(memberId);
      return {
        _id: memberId,
        username: member?.username || "Unknown",
        email: member?.email || "",
        profileImage: member?.profileImage || null,
        isGroupCreator: room.admin === memberId,
      };
    });

    res.json({
      roomId: room._id,
      roomName: room.name,
      admin: room.admin,
      memberCount: room.members.length,
      members,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Admin: remove a member from a group
export const adminRemoveMember = async (req, res) => {
  try {
    if (!ensureAdmin(req, res)) return;
    const { roomId, memberId } = req.params;

    const room = await ChatRoom.findById(roomId);
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    if (!room.members.includes(memberId)) {
      return res.status(404).json({ error: "Member not found in this room" });
    }

    if (room.admin === memberId) {
      return res.status(400).json({
        error: "Group creator cannot be removed from the group",
      });
    }

    room.members = room.members.filter((id) => id !== memberId);
    await room.save();

    await Message.updateMany(
      { roomId, readBy: memberId },
      { $pull: { readBy: memberId } }
    );

    res.json({
      message: "Member removed successfully",
      roomId,
      memberId,
      memberCount: room.members.length,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};