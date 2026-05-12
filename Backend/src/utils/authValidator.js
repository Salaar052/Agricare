// ============================================================
// authValidator.js — Authentication Input Validation (ESM)
// ============================================================

function asTrimmedString(value) {
  if (value === undefined || value === null) return "";
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length ? trimmed : "";
}

function collapseSpaces(value) {
  return value.replace(/\s+/g, " ").trim();
}

function countMatches(value, re) {
  const m = value.match(re);
  return m ? m.length : 0;
}

function isSingleRepeatedChar(value) {
  const noSpaces = value.replace(/\s+/g, "");
  if (!noSpaces) return false;
  const unique = new Set([...noSpaces]);
  return unique.size === 1;
}

export function validateEmail(rawEmail) {
  const email = asTrimmedString(rawEmail);
  if (email === null) {
    return { ok: false, email: null, message: "Email must be a string." };
  }
  if (!email) {
    return { ok: false, email: null, message: "Email is required." };
  }
  if (email.length > 254) {
    return { ok: false, email: null, message: "Email is too long." };
  }

  const normalized = email.toLowerCase();

  // Practical email format validation (avoid overly-complex RFC regex).
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
  if (!emailRegex.test(normalized)) {
    return { ok: false, email: null, message: "Please enter a valid email address." };
  }

  // Basic sanity checks (reject spaces and consecutive dots).
  if (normalized.includes(" ") || normalized.includes("..")) {
    return { ok: false, email: null, message: "Please enter a valid email address." };
  }

  return { ok: true, email: normalized, message: null };
}

export function validateUsername(rawUsername) {
  const username0 = asTrimmedString(rawUsername);
  if (username0 === null) {
    return { ok: false, username: null, message: "Username must be a string." };
  }
  const username = collapseSpaces(username0);

  if (!username) {
    return { ok: false, username: null, message: "Username is required." };
  }
  if (username.length < 3) {
    return { ok: false, username: null, message: "Username must be at least 3 characters." };
  }
  if (username.length > 30) {
    return { ok: false, username: null, message: "Username must be 30 characters or less." };
  }

  // Must contain at least 2 letters (prevents inputs like "a", "..", ",,,").
  const letterCount = countMatches(username, /\p{L}/gu);
  const alnumCount = countMatches(username, /[\p{L}\p{N}]/gu);

  if (alnumCount === 0) {
    return {
      ok: false,
      username: null,
      message: "Username cannot be only symbols or punctuation.",
    };
  }
  if (letterCount < 2) {
    return {
      ok: false,
      username: null,
      message: "Please enter a meaningful username (at least 2 letters).",
    };
  }
  if (isSingleRepeatedChar(username)) {
    return {
      ok: false,
      username: null,
      message: "Please enter a meaningful username.",
    };
  }

  return { ok: true, username, message: null };
}

export function validateLoginPassword(rawPassword) {
  if (rawPassword === undefined || rawPassword === null) {
    return { ok: false, password: null, message: "Password is required." };
  }
  if (typeof rawPassword !== "string") {
    return { ok: false, password: null, message: "Password must be a string." };
  }

  // For login we keep it permissive (existing accounts may have weaker passwords).
  const password = rawPassword;
  if (!password.trim()) {
    return { ok: false, password: null, message: "Password is required." };
  }
  if (password.length > 128) {
    return { ok: false, password: null, message: "Password is too long." };
  }

  return { ok: true, password, message: null };
}

export function validateSignupPassword(rawPassword) {
  if (rawPassword === undefined || rawPassword === null) {
    return { ok: false, password: null, message: "Password is required." };
  }
  if (typeof rawPassword !== "string") {
    return { ok: false, password: null, message: "Password must be a string." };
  }

  const password = rawPassword;
  if (!password) {
    return { ok: false, password: null, message: "Password is required." };
  }
  if (password.length < 8) {
    return { ok: false, password: null, message: "Password must be at least 8 characters." };
  }
  if (password.length > 128) {
    return { ok: false, password: null, message: "Password is too long." };
  }
  if (/\s/.test(password)) {
    return { ok: false, password: null, message: "Password cannot contain spaces." };
  }
  if (isSingleRepeatedChar(password)) {
    return { ok: false, password: null, message: "Please choose a stronger password." };
  }

  const hasLetter = /\p{L}/u.test(password);
  const hasNumber = /\d/.test(password);
  if (!hasLetter || !hasNumber) {
    return {
      ok: false,
      password: null,
      message: "Password must include at least 1 letter and 1 number.",
    };
  }

  const weak = new Set([
    "password",
    "password123",
    "12345678",
    "123456789",
    "qwerty",
    "qwerty123",
    "11111111",
    "00000000",
  ]);
  if (weak.has(password.toLowerCase())) {
    return { ok: false, password: null, message: "Please choose a stronger password." };
  }

  return { ok: true, password, message: null };
}
