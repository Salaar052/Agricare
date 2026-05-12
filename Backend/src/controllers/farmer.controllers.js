import { Farmer } from "../models/farmer/farmer.model.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";

export const registerFarmer = async (req, res, next) => {
  try {
    // ✅ Read farmerUid from request body
    const { farmerUid, fullName, phone, address, email } = req.body;

    console.log("📝 Registration attempt:", { farmerUid, email, fullName, phone });

    // Validate UID
    if (!farmerUid) {
      console.log("❌ Missing farmerUid in request");
      return next(new ApiError(400, "Firebase UID (farmerUid) is required"));
    }

    // Check if farmer already exists
    let farmer = await Farmer.findOne({ firebaseUid: farmerUid });

    if (farmer) {
      console.log("✅ Farmer already exists, returning existing record");
      return res
        .status(200)
        .json(new ApiResponse(200, farmer, "Farmer already registered"));
    }

    // Validate email
    if (!email) {
      console.log("❌ Email missing in request");
      return next(new ApiError(400, "Email is required"));
    }

    // Check if email already used by another account
    const existingEmail = await Farmer.findOne({ 
      email: email.toLowerCase(),
      firebaseUid: { $ne: farmerUid } // Different UID
    });

    if (existingEmail) {
      console.log("❌ Email already registered with different account");
      return next(new ApiError(409, "Email already registered"));
    }

    // Create new farmer
    console.log("🆕 Creating new farmer record");
    farmer = await Farmer.create({
      firebaseUid: farmerUid,
      email: email.toLowerCase().trim(),
      fullName: fullName?.trim() || "",
      phone: phone?.trim() || "",
      address: address?.trim() || "",
      profileCompleted: !!(fullName && phone),
    });

    console.log("✅ Farmer created successfully:", farmer._id);

    return res
      .status(201)
      .json(new ApiResponse(201, farmer, "Farmer registration successful"));
  } catch (err) {
    console.error("❌ Registration error:", err);

    // Handle MongoDB duplicate key errors
    if (err.code === 11000) {
      const field = Object.keys(err.keyPattern || {})[0];
      const message = field === 'firebaseUid' 
        ? "User account already exists"
        : `${field} already registered`;
      return next(new ApiError(409, message));
    }

    next(new ApiError(500, `Registration failed: ${err.message}`));
  }
};

export const loginFarmer = async (req, res, next) => {
  try {
    const { farmerUid } = req;

    console.log("🔐 Login attempt for UID:", farmerUid);

    const farmer = await Farmer.findOne({ firebaseUid: farmerUid });

    if (!farmer) {
      console.log("❌ Farmer not found in database");
      return next(new ApiError(404, "Farmer not found. Please complete registration"));
    }

    console.log("✅ Farmer found:", farmer.email);

    return res
      .status(200)
      .json(new ApiResponse(200,farmer,  "Farmer login successful"));
  } catch (err) {
    console.error("❌ Login error:", err);
    next(new ApiError(500, `Login failed: ${err.message}`));
  }
};

export const getMyProfile = async (req, res, next) => {
  try {
    const farmer = await Farmer.findOne({ firebaseUid: req.farmerUid });

    if (!farmer) {
      return next(new ApiError(404, "Farmer profile not found"));
    }

    return res
      .status(200)
      .json(new ApiResponse(200, farmer, "Profile fetched successfully"));
  } catch (err) {
    console.error("❌ Profile fetch error:", err);
    next(new ApiError(500, `Failed to fetch profile: ${err.message}`));
  }
};

export const logoutFarmer = async (req, res, next) => {
  try {
    // If you store refresh tokens in DB, delete/invalidate them here
    // Example: await Token.deleteMany({ userId: req.farmerUid });

    // Clear cookies (if any)
    res.clearCookie("token"); // clear auth cookie if you use one

    // Respond success
    return res
      .status(200)
      .json(new ApiResponse(200, null, "Farmer logged out successfully"));
  } catch (err) {
    next(new ApiError(500, `Logout failed: ${err.message}`));
  }
};
