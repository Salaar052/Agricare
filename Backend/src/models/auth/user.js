
// ============================================
// BACKEND FIXES
// ============================================

// ============================================
// 1. FIXED USER MODEL (models/auth/user.js)
// ============================================
import mongoose from "mongoose";

const { Schema } = mongoose;

const userSchema = new Schema(
  {
    username: { 
      type: String, 
      required: [true, "Username is required"],
      minlength: [3, "Username must be at least 3 characters"],
      maxlength: [30, "Username must be less than 30 characters"],
      trim: true
    },
    password: { 
      type: String, 
      required: [true, "Password is required"],
      minlength: [6, "Password must be at least 6 characters"]
    },
    email: { 
      type: String, 
      required: [true, "Email is required"],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, "Please enter a valid email"]
    },
    profileImage: { 
      type: String, 
      default: "" 
    },
    isAdmin: {
      type: Boolean,
      default: false
    },
    lastAdminLoginAt: {
      type: Date,
      default: null
    },
    haveMarketplaceAccount: {
      type: Boolean,
      default: false  // ← Changed from true to false
    },
    // Users can save marketplace items even without a seller profile.
    savedItems: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Item",
      },
    ]
    ,
    // Email verification
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    emailVerifiedAt: {
      type: Date,
      default: null,
    },
    emailVerificationTokenHash: {
      type: String,
      default: null,
    },
    emailVerificationExpiresAt: {
      type: Date,
      default: null,
    },
    emailVerificationLastSentAt: {
      type: Date,
      default: null,
    }
    ,
    // Password reset
    passwordResetTokenHash: {
      type: String,
      default: null,
    },
    passwordResetExpiresAt: {
      type: Date,
      default: null,
    },
    passwordResetLastSentAt: {
      type: Date,
      default: null,
    }
  },
  { 
    timestamps: true 
  }
);

const User = mongoose.model("User", userSchema);

export default User;