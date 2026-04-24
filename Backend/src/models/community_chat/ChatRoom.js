import mongoose from "mongoose";

const chatRoomSchema = new mongoose.Schema({
  name: { 
    type: String, 
    required: true 
  },
  image: { 
    type: String, 
    default: null 
  },
  isPublic: { 
    type: Boolean, 
    default: true 
  },
  admin: { 
    type: String, 
    required: true 
  },
  members: [{ 
    type: String 
  }],
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
});

// Index for search functionality
chatRoomSchema.index({ name: 'text' });

export default mongoose.model("ChatRoom", chatRoomSchema);