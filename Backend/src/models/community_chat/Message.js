import mongoose from "mongoose";

const messageSchema = new mongoose.Schema({
  roomId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: "ChatRoom", 
    required: true 
  },
  sender: { 
    type: String, 
    required: true 
  },
  message: { 
    type: String 
  },
  senderName: { 
    type: String 
  },
  fileUrl: { 
    type: String, 
    default: null 
  },
  readBy: [{ 
    type: String 
  }],
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
});

export default mongoose.model("Message", messageSchema);