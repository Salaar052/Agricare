// ============================================
// 4. AUTH SERVICE (services/auth/auth.js)
// ============================================
import jwt from "jsonwebtoken";
import ENV from "../../utils/ENV.js";

export function generateToken(userId, res) {
  const token = jwt.sign(
    { userId }, 
    ENV.JWT_SECRET, 
    { expiresIn: "7d" }
  );

  // Set HTTP-only cookie
  res.cookie("jwt", token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict",
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
    path: "/",
  });

  return token;
}
