import { v2 as cloudinary } from "cloudinary";
import multer from "multer";


cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});


const storage = multer.memoryStorage();

export const uploadRoomImage = multer({ storage });
export const uploadChatFile = multer({ storage });

// ---------------------------
// UPLOAD ROOM IMAGE TO CLOUDINARY
// ---------------------------
export const uploadRoomToCloudinary = async (file) => {
  if (!file) return null;

  const result = await cloudinary.uploader.upload_stream({
    folder: "chat_rooms",
    transformation: [{ width: 400, height: 400, crop: "fill" }],
  }, (error, result) => {
    if (error) throw error;
    return result;
  });

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder: "chat_rooms", transformation: [{ width: 400, height: 400, crop: "fill" }] },
      (error, result) => {
        if (error) reject(error);
        else resolve(result.secure_url);
      }
    );
    stream.end(file.buffer);
  });
};

// ---------------------------
// UPLOAD CHAT FILE TO CLOUDINARY
// ---------------------------
export const uploadChatFileToCloudinary = async (file) => {
  if (!file) return null;

  let folder = "chat_files";

  if (file.mimetype.startsWith("image/")) folder = "chat_files/images";
  else if (file.mimetype.startsWith("video/")) folder = "chat_files/videos";
  else folder = "chat_files/docs";

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder, resource_type: "auto" },
      (error, result) => {
        if (error) reject(error);
        else resolve(result.secure_url);
      }
    );
    stream.end(file.buffer);
  });
};

export default cloudinary;
