// ============================================
// 3. controllers/upload.controllers.js
// ============================================
import { asyncHandler } from "../../utils/asyncHandler.js";
import { ApiError } from "../../utils/ApiError.js";
import { ApiResponse } from "../../utils/ApiResponse.js";
import { uploadToCloudinary } from "../../middlewares/marketplace/upload.middleware.js";

// Upload single image
export const uploadSingleImage = asyncHandler(async (req, res) => {
  if (!req.file) {
    throw new ApiError(400, "No image file provided");
  }

  const result = await uploadToCloudinary(req.file.path);

  return res.status(200).json(
    new ApiResponse(200, {
      imageUrl: result.secure_url,
      publicId: result.public_id,
    }, "Image uploaded successfully")
  );
});

// Upload multiple images
export const uploadMultipleImages = asyncHandler(async (req, res) => {
  if (!req.files || req.files.length === 0) {
    throw new ApiError(400, "No image files provided");
  }

  const uploadPromises = req.files.map(file => uploadToCloudinary(file.path));
  const results = await Promise.all(uploadPromises);

  const images = results.map(result => ({
    imageUrl: result.secure_url,
    publicId: result.public_id,
  }));

  return res.status(200).json(
    new ApiResponse(200, { images }, "Images uploaded successfully")
  );
});