import mongoose from "mongoose";

const aiChatSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200
    }
  },
  {
    timestamps: true // Automatically adds createdAt and updatedAt
  }
);

// Index for faster queries
aiChatSchema.index({ createdAt: -1 });

const AIChat = mongoose.model("AIChat", aiChatSchema);

export default AIChat;