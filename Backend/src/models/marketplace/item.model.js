import mongoose, { Schema } from "mongoose";

// Predefined categories and subcategories
const CATEGORY_OPTIONS = {
  "Seeds": ["Vegetable Seeds", "Fruit Seeds", "Crop Seeds", "Fodder Seeds"],
  "Fertilizers": ["Organic Fertilizer", "Chemical Fertilizer", "Liquid Fertilizer"],
  "Pesticides": ["Insecticides", "Herbicides", "Fungicides"],
  "Machinery": ["Tractors", "Sprayers", "Harvesters", "Attachments"],
  "Livestock": ["Cows", "Goats", "Buffalo", "Sheep", "Poultry"],
};

const itemSchema = new Schema(
  {
    sellerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "MarketplaceProfile",
      required: true,
    },

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    title: { type: String, required: true },

    // Must match predefined categories
    category: {
      type: String,
      required: true,
      enum: Object.keys(CATEGORY_OPTIONS),
    },

    subcategory: {
      type: String,
      required: true,
      validate: {
        validator: function (value) {
          return CATEGORY_OPTIONS[this.category]?.includes(value);
        },
        message: "Invalid subcategory for selected category.",
      },
    },

    price: { type: Number, required: true },
    description: { type: String },

    images: [{ type: String }],

    condition: {
      type: String,
      enum: ["new", "used"],
      default: "new",
    },

    location: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number],
        default: [0, 0],
      },
      address: { type: String },
    },


    // ⭐ Admin approval system
    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
    },

    rejectionReason: {
      type: String,
      default: null,
    },

    isAvailable: {
      type: Boolean,
      default: true,
    },
    isSold: {
      type: Boolean,
      default: false,
    }
  },
  { timestamps: true }
);

// 🔹 Approve item (admin action)
itemSchema.methods.approve = function () {
  this.status = "approved";
  this.rejectionReason = null;
  return this.save();
};

// 🔹 Reject item (admin action)
itemSchema.methods.reject = function (reason) {
  this.status = "rejected";
  this.rejectionReason = reason;
  return this.save();
};

export const Item = mongoose.model("Item", itemSchema);
export const CATEGORY_LIST = CATEGORY_OPTIONS;
