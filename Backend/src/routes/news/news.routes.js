import { Router } from "express";
import { verifyJwt } from "../../middlewares/authentication.js";
import { requireAdmin } from "../../middlewares/requireAdmin.js";
import { uploadNewsImage } from "../../middlewares/news/newsUpload.middleware.js";
import {
  createNews,
  deleteNewsById,
  getNewsById,
  getNewsList,
} from "../../controllers/news/news.controllers.js";

const router = Router();

// Public: users fetch published news
router.get("/", getNewsList);
router.get("/:id", getNewsById);

// Admin: create/delete
router.post(
  "/",
  verifyJwt,
  requireAdmin,
  uploadNewsImage.fields([
    { name: "images", maxCount: 10 },
    { name: "image", maxCount: 1 },
  ]),
  createNews
);
router.delete("/:id", verifyJwt, requireAdmin, deleteNewsById);

export default router;
