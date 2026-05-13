import { v2 as cloudinary } from "cloudinary";

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// ---------------------------
// ROOM IMAGE UPLOAD (FIXED)
// ---------------------------
export const uploadRoomToCloudinary = (file) => {
  if (!file) return null;

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: "chat_rooms",
        resource_type: "image",
        transformation: [{ width: 400, height: 400, crop: "fill" }],
      },
      (error, result) => {
        if (error) return reject(error);
        resolve(result.secure_url);
      }
    );

    stream.end(file.buffer);
  });
};

// ---------------------------
// CHAT FILE UPLOAD (FIXED)
// ---------------------------
export const uploadChatFileToCloudinary = (file) => {
  if (!file) return null;

  const mime = typeof file.mimetype === "string" ? file.mimetype : "";
  let folder = "chat_files";

  if (mime.startsWith("image/")) {
    folder = "chat_files/images";
  } else if (mime.startsWith("video/")) {
    folder = "chat_files/videos";
  } else {
    folder = "chat_files/docs";
  }

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: "auto",
      },
      (error, result) => {
        if (error) return reject(error);
        resolve(result.secure_url);
      }
    );

    stream.end(file.buffer);
  });
};

export default cloudinary;