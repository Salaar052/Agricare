export function requireAdmin(req, res, next) {
  if (!req.user?.isAdmin) {
    return res.status(403).json({
      success: false,
      message: "Admin access required",
    });
  }

  return next();
}
