// ============================================
// 2. middlewares/upload.middleware.js
// ============================================
import multer from 'multer';
//import { CloudinaryStorage } from 'multer-storage-cloudinary';
import cloudinary from '../../utils/cloudinary.js';

// Configure Cloudinary storage for multer
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'marketplace',
    // Mobile galleries may include HEIC/HEIF (iOS) and some clients send octet-stream.
    // Cloudinary can handle these and will deliver optimized formats.
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
    transformation: [
      { width: 1200, height: 1200, crop: 'limit' },
      { quality: 'auto' }
    ],
  },
});

// Create multer upload instance
export const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedExts = new Set(['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif']);
    const name = (file.originalname || '').toLowerCase();
    const dot = name.lastIndexOf('.');
    const ext = dot >= 0 ? name.slice(dot) : '';

    // Preferred: trust explicit image/* mimetype.
    if (typeof file.mimetype === 'string' && file.mimetype.startsWith('image/')) {
      return cb(null, true);
    }

    // Some mobile clients (or Dart http multipart) may send application/octet-stream.
    // Accept it (Cloudinary will validate actual content; size is still limited).
    if (file.mimetype === 'application/octet-stream') {
      if (allowedExts.has(ext)) return cb(null, true);
      return cb(new Error('Invalid file type. Please upload an image (JPG/PNG/WebP/HEIC).'));
    }

    return cb(new Error('Invalid file type. Please upload an image (JPG/PNG/WebP/HEIC).'));
  },
});

// Helper function to delete image from Cloudinary
export const deleteImage = async (imageUrl) => {
  try {
    // Extract public_id from URL
    const urlParts = imageUrl.split('/');
    const publicIdWithExt = urlParts[urlParts.length - 1];
    const publicId = `marketplace/${publicIdWithExt.split('.')[0]}`;
    
    await cloudinary.uploader.destroy(publicId);
    return true;
  } catch (error) {
    console.error('Error deleting image from Cloudinary:', error);
    return false;
  }
};