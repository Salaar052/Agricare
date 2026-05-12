import {
  validateEmail,
  validateLoginPassword,
  validateSignupPassword,
  validateUsername,
} from "../utils/authValidator.js";

function badRequest(res, { message, errors }) {
  return res.status(400).json({
    success: false,
    message,
    errors,
  });
}

export function validateSignup(req, res, next) {
  const errors = [];

  const usernameRes = validateUsername(req.body?.username);
  if (!usernameRes.ok) {
    errors.push({ field: "username", message: usernameRes.message });
  }

  const emailRes = validateEmail(req.body?.email);
  if (!emailRes.ok) {
    errors.push({ field: "email", message: emailRes.message });
  }

  const passwordRes = validateSignupPassword(req.body?.password);
  if (!passwordRes.ok) {
    errors.push({ field: "password", message: passwordRes.message });
  }

  if (errors.length) {
    const message = errors[0]?.message || "Invalid signup input.";
    return badRequest(res, { message, errors });
  }

  req.body.username = usernameRes.username;
  req.body.email = emailRes.email;
  req.body.password = passwordRes.password;
  return next();
}

export function validateLogin(req, res, next) {
  const errors = [];

  const emailRes = validateEmail(req.body?.email);
  if (!emailRes.ok) {
    errors.push({ field: "email", message: emailRes.message });
  }

  const passwordRes = validateLoginPassword(req.body?.password);
  if (!passwordRes.ok) {
    errors.push({ field: "password", message: passwordRes.message });
  }

  if (errors.length) {
    const message = errors[0]?.message || "Invalid login input.";
    return badRequest(res, { message, errors });
  }

  req.body.email = emailRes.email;
  req.body.password = passwordRes.password;
  return next();
}

export function validateEmailOnly(req, res, next) {
  const emailRes = validateEmail(req.body?.email);
  if (!emailRes.ok) {
    return badRequest(res, {
      message: emailRes.message,
      errors: [{ field: "email", message: emailRes.message }],
    });
  }

  req.body.email = emailRes.email;
  return next();
}

export function validateResetPassword(req, res, next) {
  // POST /reset-password expects token + newPassword
  const errors = [];

  const token = req.body?.token;
  if (!token || typeof token !== "string" || !token.trim()) {
    errors.push({ field: "token", message: "Reset token is required." });
  }

  const passwordRes = validateSignupPassword(req.body?.newPassword);
  if (!passwordRes.ok) {
    errors.push({ field: "newPassword", message: passwordRes.message });
  }

  if (errors.length) {
    const message = errors[0]?.message || "Invalid reset password input.";
    return badRequest(res, { message, errors });
  }

  req.body.token = token;
  req.body.newPassword = passwordRes.password;
  return next();
}
