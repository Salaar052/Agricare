import mongoose from "mongoose";

const farmerSchema = new mongoose.Schema(
  {
    firebaseUid: {
      type: String,
      unique: true,
      required: true,
      index: true
    },
    email: {
      type: String,
      required: true,
      lowercase: true,
      trim: true
    },

    // App personal fields (add more whenever required)
    fullName: { type: String },
    phone: { 
      type: String,
      trim: true,
      sparse: true,
     },
    address: { type: String },

    profileCompleted: {
      type: Boolean,
      default: false,
    },
    haveMarketplaceAccount: {
      type: Boolean,
      default: false
    }
  },
  { timestamps: true }
);
farmerSchema.index({ email: 1, firebaseUid: 1 });

export const Farmer = mongoose.model("Farmer", farmerSchema);
