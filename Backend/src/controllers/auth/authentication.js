// ============================================
// 2. AUTH CONTROLLERS (controllers/auth/authentication.js)
// ============================================
import User from "../../models/auth/user.js";
import bcrypt from "bcrypt";
import { generateToken } from "../../services/auth/auth.js";
import cloudinary from "../../utils/cloudinary.js";

export async function signupHandler(req, res) {
  console.log("signup hit")
  try {
    const { username, password } = req.body;
    let email = req.body.email?.toLowerCase()?.trim();

    // Validation
    if (!username?.trim() || !password || !email) {
      return res.status(400).json({ 
        success: false,
        message: "All fields are required" 
      });
    }

    if (username.trim().length < 3) {
      return res.status(400).json({ 
        success: false,
        message: "Username must be at least 3 characters long" 
      });
    }

    if (password.length < 6) {
      return res.status(400).json({ 
        success: false,
        message: "Password must be at least 6 characters long" 
      });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ 
        success: false,
        message: "Invalid email format" 
      });
    }

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ 
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
    });

    const savedUser = await newUser.save();

    // Generate token and set cookie
    const token = generateToken(savedUser._id, res);

    return res.status(201).json({
      success: true,
      message: "Account created successfully",
      _id: savedUser._id,
      username: savedUser.username,
      email: savedUser.email,
      profileImage: savedUser.profileImage,
      token,
    });
  } catch (error) {
    console.error("Signup error:", error);
    return res.status(500).json({ 
      success: false,
      message: "Internal server error. Please try again later." 
    });
  }
}

export async function loginHandler(req, res) {
  try {
    console.log("login hit");
    const { password } = req.body;
    let email = req.body.email?.toLowerCase()?.trim();

    // Validation
    if (!email || !password) {
      return res.status(400).json({ 
        success: false,
        message: "Email and password are required" 
      });
    }

    // Find user
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

    // Generate token and set cookie
    const token = generateToken(user._id, res);

    return res.status(200).json({
      success: true,
      message: "Login successful",
      _id: user._id,
      username: user.username,
      email: user.email,
      profileImage: user.profileImage,
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