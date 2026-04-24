// ============================================
// 1. AUTH ROUTES (routes/auth/authentication.js)
// ============================================
import express from "express";
import {
  signupHandler,
  loginHandler,
  logoutHandler,
  updateProfileImageHandler,
  checkAuthHandler,
} from "../../controllers/auth/authentication.js";
import { verifyJwt } from "../../middlewares/authentication.js";

const router = express.Router();

// Public routes
router.post("/signup", signupHandler);
router.post("/login", loginHandler);

// Protected routes
router.post("/logout", verifyJwt, logoutHandler);
router.put("/updateProfileImage", verifyJwt, updateProfileImageHandler);
router.get("/check", verifyJwt, checkAuthHandler);

export default router;