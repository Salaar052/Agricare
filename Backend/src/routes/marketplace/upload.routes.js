// ============================================
// 4. routes/upload.routes.js
// ============================================
import { Router } from "express";
import { upload } from "../../middlewares/marketplace/upload.middleware.js";
import { uploadSingleImage, uploadMultipleImages } from "../../controllers/marketplace/upload.controllers.js";
import { verifyJwt } from "../../middlewares/authentication.js";

const uploadRouter = Router();

// Require authentication for uploads
uploadRouter.use(verifyJwt);

// Upload single image
uploadRouter.post("/single", upload.single('image'), uploadSingleImage);

// Upload multiple images (max 10)
uploadRouter.post("/multiple", upload.array('images', 10), uploadMultipleImages);

export default uploadRouter;