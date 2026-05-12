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
  updateAdminProfileHandler,
  getAllFarmersForAdminHandler,
  getFarmerDetailsForAdminHandler,
  disableSellerAccountHandler,
  enableSellerAccountHandler,
  deleteSellerAccountHandler,
  changeAdminPasswordHandler,
} from "../../controllers/auth/authentication.js";
import {
  verifyEmailHandler,
  resendVerificationEmailHandler,
} from "../../controllers/auth/emailVerification.controller.js";
import {
  requestPasswordResetHandler,
  resetPasswordHandler,
} from "../../controllers/auth/passwordReset.controller.js";
import { verifyJwt } from "../../middlewares/authentication.js";
import {
  validateEmailOnly,
  validateLogin,
  validateResetPassword,
  validateSignup,
} from "../../middlewares/authValidation.js";

const router = express.Router();

// Public routes
router.post("/signup", validateSignup, signupHandler);
router.post("/login", validateLogin, loginHandler);
router.get("/verify-email", verifyEmailHandler);
router.post("/verify-email", verifyEmailHandler);
router.post("/resend-verification", validateEmailOnly, resendVerificationEmailHandler);

// Forgot/Reset password
router.post("/forgot-password", validateEmailOnly, requestPasswordResetHandler);
router.get("/reset-password", resetPasswordHandler);
router.post("/reset-password", validateResetPassword, resetPasswordHandler);

// Protected routes
router.post("/logout", verifyJwt, logoutHandler);
router.put("/updateProfileImage", verifyJwt, updateProfileImageHandler);
router.get("/check", verifyJwt, checkAuthHandler);
router.put("/admin/profile", verifyJwt, updateAdminProfileHandler);
router.put("/admin/change-password", verifyJwt, changeAdminPasswordHandler);
router.get("/admin/farmers", verifyJwt, getAllFarmersForAdminHandler);
router.get("/admin/farmers/:userId", verifyJwt, getFarmerDetailsForAdminHandler);
router.put("/admin/sellers/:userId/disable", verifyJwt, disableSellerAccountHandler);
router.put("/admin/sellers/:userId/enable", verifyJwt, enableSellerAccountHandler);
router.delete("/admin/sellers/:userId", verifyJwt, deleteSellerAccountHandler);

export default router;