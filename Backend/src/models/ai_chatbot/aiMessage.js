import mongoose from "mongoose";

const aiMessageSchema = new mongoose.Schema({
  chatId: { type: mongoose.Schema.Types.ObjectId, ref: "AIChat" },
  sender: { type: String, enum: ["user", "bot"] },
  message: String,
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model("AIMessage", aiMessageSchema);