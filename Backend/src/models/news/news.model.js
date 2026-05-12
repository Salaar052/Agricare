import mongoose from "mongoose";

const localizedTextSchema = new mongoose.Schema(
  {
    en: { type: String, trim: true, default: "" },
    ur: { type: String, trim: true, default: "" },
  },
  { _id: false }
);

const newsSchema = new mongoose.Schema(
  {
    headline: { type: localizedTextSchema, default: () => ({}) },
    description: { type: localizedTextSchema, default: () => ({}) },
    images: {
      type: [
        {
          url: { type: String, trim: true, default: "" },
          publicId: { type: String, trim: true, default: "" },
        },
      ],
      default: () => [],
    },
    image: {
      url: { type: String, trim: true, default: "" },
      publicId: { type: String, trim: true, default: "" },
    },
    language: {
      type: String,
      enum: ["both", "en", "ur"],
      default: "both",
    },
    isPublished: {
      type: Boolean,
      default: true,
    },
    publishedAt: {
      type: Date,
      default: null,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  { timestamps: true }
);

newsSchema.index({ isPublished: 1, publishedAt: -1, createdAt: -1 });

export const News = mongoose.model("News", newsSchema);
