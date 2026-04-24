// ============================================
// FIXED AUTH MIDDLEWARE (middlewares/authentication.js)
// Now supports BOTH cookies AND Authorization header
// ============================================

import ENV from "../utils/ENV.js";
import jwt from "jsonwebtoken";
import User from "../models/auth/user.js";

export async function verifyJwt(req, res, next) {
  try {
    let token = null;

    // ✅ CHECK 1: Authorization header (for Flutter/mobile apps)
    if (req.headers.authorization?.startsWith("Bearer ")) {
      token = req.headers.authorization.split(" ")[1];
      console.log('🔑 Token found in Authorization header');
    }
    
    // ✅ CHECK 2: Cookie (for web browsers)
    if (!token && req.cookies.jwt) {
      token = req.cookies.jwt;
      console.log('🔑 Token found in cookie');
    }

    // No token found in either location
    if (!token) {
      console.log('❌ No token found in Authorization header OR cookies');
      return res.status(401).json({ 
        success: false,
        message: "Authentication required. Please login." 
      });
    }

    console.log('🔐 Verifying token:', token.substring(0, 20) + '...');

    // Verify token
    let decoded;
    try {
      decoded = jwt.verify(token, ENV.JWT_SECRET);
      console.log('✅ Token verified successfully');
      console.log('👤 User ID from token:', decoded.userId);
    } catch (error) {
      console.error('❌ Token verification failed:', error.message);
      
      if (error.name === "TokenExpiredError") {
        return res.status(401).json({ 
          success: false,
          message: "Session expired. Please login again." 
        });
      }
      return res.status(401).json({ 
        success: false,
        message: "Invalid authentication token" 
      });
    }

    // Find user
    const user = await User.findById(decoded.userId).select("-password");
    if (!user) {
      console.error('❌ User not found in database:', decoded.userId);
      return res.status(401).json({ 
        success: false,
        message: "User not found. Please login again." 
      });
    }

    console.log('✅ User authenticated:', user.email);

    req.user = user;
    next();
  } catch (error) {
    console.error("❌ JWT verification error:", error);
    return res.status(500).json({ 
      success: false,
      message: "Authentication error" 
    });
  }
}