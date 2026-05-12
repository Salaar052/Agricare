import mongoose, { Schema } from 'mongoose'
import { normalizeWhatsAppNumber, isValidWhatsAppNumberDigits } from "../../utils/phone.js";


const marketplaceProfileSchema = new Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true, // one user → one seller profile
    },

    shopName: { type: String, required: true },

    shopDescription: { type: String },

    sellerBio: { type: String},

    shopImage: { type: String },

    whatsapp_number: {
      type: String,
      trim: true,
      default: "",
      set: (value) => normalizeWhatsAppNumber(value),
      validate: {
        validator: (value) => {
          if (!value) return true;
          return isValidWhatsAppNumberDigits(value);
        },
        message:
          "Invalid WhatsApp number. Use international format like +923001234567 (country code + number).",
      },
    },

    // Contact info (auto-fill from user profile)
    contactInfo: {
      name: {type: String},  
      phone: { type: String },
      email: { type: String },
    },
    isActive: { type: Boolean, default: true },

    address: { type: String },

    geoLocation: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number],
        default: [0, 0],
      }
    },
    items: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Item",
      },
    ],
    savedItems: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Item",
      },
    ],
  },
  { timestamps: true }
);

// Fast account-status checks
marketplaceProfileSchema.index({ userId: 1, isActive: 1 });

export const MarketplaceProfile = mongoose.model(
  "MarketplaceProfile",
  marketplaceProfileSchema
);
