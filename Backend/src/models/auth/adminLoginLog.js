import mongoose from "mongoose";

const { Schema } = mongoose;

const adminLoginLogSchema = new Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },
    email: {
      type: String,
      required: true,
      lowercase: true,
      trim: true
    },
    loginAt: {
      type: Date,
      default: Date.now
    }
  },
  { timestamps: true }
);

const AdminLoginLog = mongoose.model("AdminLoginLog", adminLoginLogSchema);

export default AdminLoginLog;
