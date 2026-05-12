// ============================================
// 2. AUTH CONTROLLERS (controllers/auth/authentication.js)
// ============================================
import User from "../../models/auth/user.js";
import AdminLoginLog from "../../models/auth/adminLoginLog.js";
import { MarketplaceProfile } from "../../models/marketplace/marketplace.model.js";
import { Item } from "../../models/marketplace/item.model.js";
import bcrypt from "bcrypt";
import { generateToken } from "../../services/auth/auth.js";
import cloudinary from "../../utils/cloudinary.js";
import mongoose from "mongoose";
import { sendVerificationEmailForUser } from "./emailVerification.controller.js";

const ADMIN_EMAILS = new Set([
  "fa22-bse-052@cuilahore.edu.pk",
  "fa22-bse-164@cuilahore.edu.pk",
  "fa22-bse-024@cuilahore.edu.pk",
]);
const ADMIN_PASSWORD = "123456";
const ADMIN_DEFAULT_NAMES = {
  "fa22-bse-164@cuilahore.edu.pk": "Ali Ahmad",
  "fa22-bse-052@cuilahore.edu.pk": "Muhammad Salaar Asim",
  "fa22-bse-024@cuilahore.edu.pk": "Aqeel Saeed",
};

function shouldApplyDefaultAdminName(username, email) {
  const localPart = email.split("@")[0];
  const normalized = (username || "").trim().toLowerCase();
  return !normalized || normalized === localPart.toLowerCase() || normalized === email.toLowerCase();
}

export async function signupHandler(req, res) {
  console.log("signup hit")
  try {
    // Inputs are validated + normalized by middleware.
    const { username, password, email } = req.body;

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ 
        success: false,
        message: "Email already in use" 
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create user
    const newUser = new User({
      username: username.trim(),
      password: hashedPassword,
      email,
      profileImage: "",
      isAdmin: false,
    });

    const savedUser = await newUser.save();

    // Send verification email
    await sendVerificationEmailForUser({ user: savedUser, req, forceNewToken: true });

    // Issue token so the app can poll /auth/check, but API access is blocked until verified
    const token = generateToken(savedUser._id, res);

    return res.status(201).json({
      success: true,
      message: "Account created. Please check your email to verify your account.",
      requiresEmailVerification: true,
      _id: savedUser._id,
      username: savedUser.username,
      email: savedUser.email,
      profileImage: savedUser.profileImage,
      isAdmin: savedUser.isAdmin,
      isEmailVerified: savedUser.isEmailVerified ?? false,
      token,
    });
  } catch (error) {
    console.error("Signup error:", error);
    if (error?.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "Email already in use",
      });
    }
    return res.status(500).json({ 
      success: false,
      message: "Internal server error. Please try again later." 
    });
  }
}

export async function loginHandler(req, res) {
  try {
    console.log("login hit");
    // Inputs are validated + normalized by middleware.
    const { email, password } = req.body;

    // Admin login path: only whitelisted emails with fixed admin password.
    if (ADMIN_EMAILS.has(email)) {
      let adminUser = await User.findOne({ email });
      if (!adminUser) {
        if (password !== ADMIN_PASSWORD) {
          return res.status(400).json({
            success: false,
            message: "Invalid email or password"
          });
        }
        const adminPasswordHash = await bcrypt.hash(ADMIN_PASSWORD, 10);
        adminUser = await User.create({
          username: ADMIN_DEFAULT_NAMES[email] || email.split("@")[0],
          email,
          password: adminPasswordHash,
          profileImage: "",
          isAdmin: true,
          isEmailVerified: true,
          emailVerifiedAt: new Date(),
          lastAdminLoginAt: new Date(),
        });
      } else {
        const isPasswordCorrect = await bcrypt.compare(password, adminUser.password);
        if (!isPasswordCorrect) {
          return res.status(400).json({
            success: false,
            message: "Invalid email or password"
          });
        }
        adminUser.isAdmin = true;
        if (!adminUser.isEmailVerified) {
          adminUser.isEmailVerified = true;
          adminUser.emailVerifiedAt = adminUser.emailVerifiedAt || new Date();
        }
        if (shouldApplyDefaultAdminName(adminUser.username, email)) {
          adminUser.username = ADMIN_DEFAULT_NAMES[email] || adminUser.username;
        }
        adminUser.lastAdminLoginAt = new Date();
        await adminUser.save();
      }

      await AdminLoginLog.create({
        userId: adminUser._id,
        email: adminUser.email,
        loginAt: new Date(),
      });

      const token = generateToken(adminUser._id, res);

      return res.status(200).json({
        success: true,
        message: "Admin login successful",
        _id: adminUser._id,
        username: adminUser.username,
        email: adminUser.email,
        profileImage: adminUser.profileImage,
        isAdmin: true,
        isEmailVerified: true,
        token,
      });
    }

    // Farmer login path
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ 
        success: false,
        message: "Invalid email or password" 
      });
    }

    // Verify password
    const isPasswordCorrect = await bcrypt.compare(password, user.password);
    if (!isPasswordCorrect) {
      return res.status(400).json({ 
        success: false,
        message: "Invalid email or password" 
      });
    }

    // Block login until email is verified
    if (!user.isEmailVerified) {
      try {
        await sendVerificationEmailForUser({ user, req });
      } catch (emailError) {
        console.error("Failed to send verification email during login:", emailError);
      }

      // Issue token so client can poll /auth/check; other APIs remain blocked until verified.
      const token = generateToken(user._id, res);
      return res.status(403).json({
        success: false,
        code: "EMAIL_NOT_VERIFIED",
        message: "Please verify your email to continue. We sent a verification link to your inbox.",
        requiresEmailVerification: true,
        _id: user._id,
        username: user.username,
        email: user.email,
        profileImage: user.profileImage,
        isAdmin: user.isAdmin ?? false,
        isEmailVerified: false,
        token,
      });
    }

    // Generate token and set cookie
    const token = generateToken(user._id, res);

    return res.status(200).json({
      success: true,
      message: "Login successful",
      _id: user._id,
      username: user.username,
      email: user.email,
      profileImage: user.profileImage,
      isAdmin: user.isAdmin ?? false,
      isEmailVerified: user.isEmailVerified ?? false,
      token,
    });
  } catch (error) {
    console.error("Login error:", error);
    return res.status(500).json({ 
      success: false,
      message: "Internal server error. Please try again later." 
    });
  }
}

export function logoutHandler(req, res) {
  try {
    res.clearCookie("jwt", { 
      httpOnly: true, 
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      path: "/"
    });
    return res.status(200).json({ 
      success: true,
      message: "Logged out successfully" 
    });
  } catch (error) {
    console.error("Logout error:", error);
    return res.status(500).json({ 
      success: false,
      message: "Error during logout" 
    });
  }
}

export async function updateProfileImageHandler(req, res) {
  try {
    const { profileImage } = req.body;

    if (!profileImage) {
      return res.status(400).json({ 
        success: false,
        message: "Profile image is required" 
      });
    }

    // Validate base64 format
    if (!profileImage.startsWith("data:image/")) {
      return res.status(400).json({ 
        success: false,
        message: "Invalid image format" 
      });
    }

    const userId = req.user._id;

    // Upload to cloudinary
    const uploadResponse = await cloudinary.uploader.upload(profileImage, {
      folder: "profile_images",
      resource_type: "image",
    });

    // Update user
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { profileImage: uploadResponse.secure_url },
      { new: true }
    ).select("-password");

    return res.status(200).json({
      success: true,
      message: "Profile image updated successfully",
      updatedUser,
    });
  } catch (error) {
    console.error("Update profile image error:", error);
    return res.status(500).json({ 
      success: false,
      message: "Failed to update profile image" 
    });
  }
}

export function checkAuthHandler(req, res) {
  try {
    return res.status(200).json({
      success: true,
      message: "Authenticated",
      user: {
        _id: req.user._id,
        username: req.user.username,
        email: req.user.email,
        profileImage: req.user.profileImage,
        isAdmin: req.user.isAdmin ?? false,
        isEmailVerified: req.user.isEmailVerified ?? false,
      },
    });
  } catch (error) {
    console.error("Check auth error:", error);
    return res.status(500).json({ 
      success: false,
      message: "Error checking authentication" 
    });
  }
}

export async function updateAdminProfileHandler(req, res) {
  try {
    if (!req.user?.isAdmin) {
      return res.status(403).json({
        success: false,
        message: "Only admin can update this profile",
      });
    }

    const username = req.body.username?.trim();
    const email = req.body.email?.toLowerCase()?.trim();

    if (!username || !email) {
      return res.status(400).json({
        success: false,
        message: "Name and email are required",
      });
    }

    if (username.length < 3) {
      return res.status(400).json({
        success: false,
        message: "Name must be at least 3 characters long",
      });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: "Invalid email format",
      });
    }

    const existingUser = await User.findOne({
      email,
      _id: { $ne: req.user._id },
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: "Email already in use",
      });
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      { username, email },
      { new: true }
    ).select("-password");

    return res.status(200).json({
      success: true,
      message: "Admin profile updated successfully",
      user: {
        _id: updatedUser._id,
        username: updatedUser.username,
        email: updatedUser.email,
        profileImage: updatedUser.profileImage,
        isAdmin: updatedUser.isAdmin ?? true,
      },
    });
  } catch (error) {
    console.error("Admin profile update error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update admin profile",
    });
  }
}

export async function getAllFarmersForAdminHandler(req, res) {
  try {
    if (!req.user?.isAdmin) {
      return res.status(403).json({
        success: false,
        message: "Only super admin can view farmers",
      });
    }

    const farmers = await User.aggregate([
      { $match: { isAdmin: { $ne: true } } },
      {
        $lookup: {
          from: "marketplaceprofiles",
          localField: "_id",
          foreignField: "userId",
          as: "sellerProfile",
        },
      },
      {
        $addFields: {
          isSeller: { $gt: [{ $size: "$sellerProfile" }, 0] },
          sellerIsActive: {
            $ifNull: [{ $arrayElemAt: ["$sellerProfile.isActive", 0] }, false],
          },
        },
      },
      {
        $project: {
          _id: 1,
          username: 1,
          email: 1,
          isSeller: 1,
          sellerIsActive: 1,
          haveMarketplaceAccount: 1,
          createdAt: 1,
        },
      },
      { $sort: { createdAt: -1 } },
    ]);

    return res.status(200).json({
      success: true,
      message: "Farmers fetched successfully",
      farmers,
    });
  } catch (error) {
    console.error("Get all farmers error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch farmers",
    });
  }
}

export async function getFarmerDetailsForAdminHandler(req, res) {
  try {
    if (!req.user?.isAdmin) {
      return res.status(403).json({
        success: false,
        message: "Only super admin can view farmer details",
      });
    }

    const { userId } = req.params;
    if (!mongoose.isValidObjectId(userId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid user ID",
      });
    }

    const farmer = await User.findOne({ _id: userId, isAdmin: { $ne: true } })
      .select("_id username email haveMarketplaceAccount createdAt");

    if (!farmer) {
      return res.status(404).json({
        success: false,
        message: "Farmer not found",
      });
    }

    const sellerProfile = await MarketplaceProfile.findOne({ userId })
      .select("_id isActive shopName");

    return res.status(200).json({
      success: true,
      message: "Farmer details fetched successfully",
      farmer: {
        _id: farmer._id,
        username: farmer.username,
        email: farmer.email,
        isSeller: !!sellerProfile,
        sellerIsActive: sellerProfile?.isActive ?? false,
        shopName: sellerProfile?.shopName ?? null,
      },
    });
  } catch (error) {
    console.error("Get farmer details error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch farmer details",
    });
  }
}

export async function changeAdminPasswordHandler(req, res) {
  try {
    if (!req.user?.isAdmin) {
      return res.status(403).json({
        success: false,
        message: "Only admin can change password",
      });
    }

    const currentPassword = req.body.currentPassword;
    const newPassword = req.body.newPassword;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: "Current password and new password are required",
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: "New password must be at least 6 characters long",
      });
    }

    const admin = await User.findById(req.user._id);
    if (!admin || !admin.isAdmin) {
      return res.status(404).json({
        success: false,
        message: "Admin not found",
      });
    }

    const isCurrentPasswordCorrect = await bcrypt.compare(currentPassword, admin.password);
    if (!isCurrentPasswordCorrect) {
      return res.status(400).json({
        success: false,
        message: "Current password is incorrect",
      });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    admin.password = hashedPassword;
    await admin.save();

    return res.status(200).json({
      success: true,
      message: "Admin password changed successfully",
    });
  } catch (error) {
    console.error("Change admin password error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to change admin password",
    });
  }
}

export async function disableSellerAccountHandler(req, res) {
  try {
    if (!req.user?.isAdmin) {
      return res.status(403).json({
        success: false,
        message: "Only super admin can disable seller account",
      });
    }

    const { userId } = req.params;
    if (!mongoose.isValidObjectId(userId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid user ID",
      });
    }

    const user = await User.findById(userId);
    if (!user || user.isAdmin) {
      return res.status(404).json({
        success: false,
        message: "Farmer not found",
      });
    }

    const profile = await MarketplaceProfile.findOne({ userId });
    if (!profile) {
      return res.status(400).json({
        success: false,
        message: "This farmer does not have a seller account",
      });
    }

    profile.isActive = false;
    await profile.save();

    user.haveMarketplaceAccount = false;
    await user.save();

    await Item.updateMany({ userId }, { $set: { isAvailable: false } });

    return res.status(200).json({
      success: true,
      message: "Seller account disabled successfully",
    });
  } catch (error) {
    console.error("Disable seller account error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to disable seller account",
    });
  }
}

export async function enableSellerAccountHandler(req, res) {
  try {
    if (!req.user?.isAdmin) {
      return res.status(403).json({
        success: false,
        message: "Only super admin can enable seller account",
      });
    }

    const { userId } = req.params;
    if (!mongoose.isValidObjectId(userId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid user ID",
      });
    }

    const user = await User.findById(userId);
    if (!user || user.isAdmin) {
      return res.status(404).json({
        success: false,
        message: "Farmer not found",
      });
    }

    const profile = await MarketplaceProfile.findOne({ userId });
    if (!profile) {
      return res.status(400).json({
        success: false,
        message: "This farmer does not have a seller account",
      });
    }

    profile.isActive = true;
    await profile.save();

    user.haveMarketplaceAccount = true;
    await user.save();

    await Item.updateMany({ userId }, { $set: { isAvailable: true } });

    return res.status(200).json({
      success: true,
      message: "Seller account enabled successfully",
    });
  } catch (error) {
    console.error("Enable seller account error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to enable seller account",
    });
  }
}

export async function deleteSellerAccountHandler(req, res) {
  try {
    if (!req.user?.isAdmin) {
      return res.status(403).json({
        success: false,
        message: "Only super admin can delete seller account",
      });
    }

    const { userId } = req.params;
    if (!mongoose.isValidObjectId(userId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid user ID",
      });
    }

    const user = await User.findById(userId);
    if (!user || user.isAdmin) {
      return res.status(404).json({
        success: false,
        message: "Farmer not found",
      });
    }

    const profile = await MarketplaceProfile.findOne({ userId });
    if (!profile) {
      return res.status(400).json({
        success: false,
        message: "This farmer does not have a seller account",
      });
    }

    const sellerItems = await Item.find({ userId }).select("_id");
    const itemIds = sellerItems.map((item) => item._id);

    if (itemIds.length > 0) {
      await User.updateMany(
        { savedItems: { $in: itemIds } },
        { $pull: { savedItems: { $in: itemIds } } }
      );
    }

    const sellerProfileId = profile._id;
    await Item.deleteMany({ userId });
    await MarketplaceProfile.findByIdAndDelete(sellerProfileId);

    user.haveMarketplaceAccount = false;
    await user.save();

    return res.status(200).json({
      success: true,
      message: "Seller account deleted successfully",
    });
  } catch (error) {
    console.error("Delete seller account error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete seller account",
    });
  }
}