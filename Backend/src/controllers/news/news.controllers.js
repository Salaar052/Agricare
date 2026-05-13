import { asyncHandler } from "../../utils/asyncHandler.js";
import { ApiError } from "../../utils/ApiError.js";
import { ApiResponse } from "../../utils/ApiResponse.js";
import { News } from "../../models/news/news.model.js";
import cloudinary from "../../utils/cloudinary.js";

function normalizeBool(value, defaultValue) {
  if (value === undefined || value === null || value === "") return defaultValue;
  if (typeof value === "boolean") return value;
  const v = String(value).trim().toLowerCase();
  if (["true", "1", "yes", "y"].includes(v)) return true;
  if (["false", "0", "no", "n"].includes(v)) return false;
  return defaultValue;
}

function trimOrEmpty(value) {
  return typeof value === "string" ? value.trim() : "";
}

function getUploadedImages(req) {
  const out = [];

  const pushFile = (file) => {
    if (!file) return;
    const url =
      file.path ||
      file.secure_url ||
      (typeof file.url === "string" ? file.url : "") ||
      "";
    const publicId =
      file.filename ||
      file.public_id ||
      (typeof file.publicId === "string" ? file.publicId : "") ||
      "";
    if (!url && !publicId) return;
    out.push({ url, publicId });
  };

  // multer.single
  if (req.file) pushFile(req.file);

  const files = req.files;
  if (!files) return out;

  // multer.array
  if (Array.isArray(files)) {
    for (const f of files) pushFile(f);
    return out;
  }

  // multer.fields
  if (typeof files === "object") {
    const images = files.images;
    const image = files.image;

    if (Array.isArray(images)) for (const f of images) pushFile(f);
    if (Array.isArray(image)) for (const f of image) pushFile(f);
  }

  return out;
}

export const createNews = asyncHandler(async (req, res) => {
  const headlineEn = trimOrEmpty(req.body?.headlineEn);
  const headlineUr = trimOrEmpty(req.body?.headlineUr);
  const descriptionEn = trimOrEmpty(req.body?.descriptionEn);
  const descriptionUr = trimOrEmpty(req.body?.descriptionUr);
  const language = trimOrEmpty(req.body?.language) || "both";

  const hasHeadline = !!(headlineEn || headlineUr);
  const hasDescription = !!(descriptionEn || descriptionUr);

  if (!hasHeadline) throw new ApiError(400, "Headline is required (English or Urdu)");
  if (!hasDescription) throw new ApiError(400, "Description is required (English or Urdu)");

  if (!["both", "en", "ur"].includes(language)) {
    throw new ApiError(400, "Invalid language. Use 'both', 'en', or 'ur'.");
  }

  const isPublished = normalizeBool(req.body?.isPublished, true);

  const images = getUploadedImages(req);
  if (!images.length) {
    throw new ApiError(400, "At least one image is required for news");
  }
  const image = images[0] || { url: "", publicId: "" }; // legacy compatibility

  const publishedAt = isPublished ? new Date() : null;

  const news = await News.create({
    headline: { en: headlineEn, ur: headlineUr },
    description: { en: descriptionEn, ur: descriptionUr },
    images,
    image,
    language,
    isPublished,
    publishedAt,
    createdBy: req.user._id,
  });

  return res.status(201).json(new ApiResponse(201, { news }, "News created"));
});

export const getNewsList = asyncHandler(async (req, res) => {
  const page = Math.max(1, Number(req.query.page) || 1);
  const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 10));
  const skip = (page - 1) * limit;

  const filter = { isPublished: true };

  const sort = { publishedAt: -1, createdAt: -1 };

  const [items, totalItems] = await Promise.all([
    News.find(filter).sort(sort).skip(skip).limit(limit).lean(),
    News.countDocuments(filter),
  ]);

  const totalPages = Math.max(1, Math.ceil(totalItems / limit));

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        items,
        pagination: {
          page,
          limit,
          totalItems,
          totalPages,
          hasNextPage: page < totalPages,
          hasPrevPage: page > 1,
        },
      },
      "News fetched"
    )
  );
});

export const getNewsById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const news = await News.findById(id).lean();
  if (!news) throw new ApiError(404, "News not found");

  if (!news.isPublished) throw new ApiError(404, "News not found");

  return res.status(200).json(new ApiResponse(200, { news }, "News fetched"));
});

export const deleteNewsById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const news = await News.findById(id);
  if (!news) throw new ApiError(404, "News not found");

  const publicIds = new Set();
  if (Array.isArray(news.images)) {
    for (const img of news.images) {
      if (img?.publicId) publicIds.add(String(img.publicId));
    }
  }
  if (news.image?.publicId) publicIds.add(String(news.image.publicId));

  await Promise.allSettled(
    Array.from(publicIds).map((publicId) => cloudinary.uploader.destroy(publicId))
  );

  await News.findByIdAndDelete(id);

  return res.status(200).json(new ApiResponse(200, {}, "News deleted"));
});
