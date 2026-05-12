import multer from "multer";
//import { CloudinaryStorage } from "multer-storage-cloudinary";
import cloudinary from "../../utils/cloudinary.js";

const storage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: "news",
    allowed_formats: ["jpg", "jpeg", "png", "webp", "heic", "heif"],
    transformation: [{ width: 1400, height: 900, crop: "limit" }, { quality: "auto" }],
  },
});

export const uploadNewsImage = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024,
    files: 10,
  },
  fileFilter: (req, file, cb) => {
    const allowedExts = new Set([".jpg", ".jpeg", ".png", ".webp", ".heic", ".heif"]);
    const name = (file.originalname || "").toLowerCase();
    const dot = name.lastIndexOf(".");
    const ext = dot >= 0 ? name.slice(dot) : "";

    if (typeof file.mimetype === "string" && file.mimetype.startsWith("image/")) {
      return cb(null, true);
    }

    if (file.mimetype === "application/octet-stream") {
      // Some mobile clients send octet-stream even for images. Only accept it
      // when the filename extension still looks like a valid image.
      if (allowedExts.has(ext)) return cb(null, true);
      return cb(new Error("Invalid file type. Please upload an image (JPG/PNG/WebP/HEIC)."));
    }

    return cb(new Error("Invalid file type. Please upload an image (JPG/PNG/WebP/HEIC)."));
  },
});
