// ============================================
// 3. controllers/upload.controllers.js
// ============================================
import { asyncHandler } from "../../utils/asyncHandler.js";
import { ApiError } from "../../utils/ApiError.js";
import { ApiResponse } from "../../utils/ApiResponse.js";

// Upload single image
export const uploadSingleImage = asyncHandler(async (req, res) => {
  if (!req.file) {
    throw new ApiError(400, "No image file provided");
  }

  return res.status(200).json(
    new ApiResponse(200, {
      imageUrl: req.file.path,
      publicId: req.file.filename,
    }, "Image uploaded successfully")
  );
});

// Upload multiple images
export const uploadMultipleImages = asyncHandler(async (req, res) => {
  if (!req.files || req.files.length === 0) {
    throw new ApiError(400, "No image files provided");
  }

  const imageUrls = req.files.map(file => ({
    imageUrl: file.path,
    publicId: file.filename,
  }));

  return res.status(200).json(
    new ApiResponse(200, { images: imageUrls }, "Images uploaded successfully")
  );
});