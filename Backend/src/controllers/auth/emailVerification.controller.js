import crypto from "crypto";
import User from "../../models/auth/user.js";
import ENV from "../../utils/ENV.js";
import { sendEmail } from "../../services/email/mailer.js";
import { buildVerifyEmailTemplate } from "../../services/email/templates/verifyEmail.template.js";
import { validateEmail } from "../../utils/authValidator.js";

const TOKEN_BYTES = 32;
const TOKEN_TTL_HOURS = 24;
const RESEND_COOLDOWN_SECONDS = 60;

function sha256Hex(input) {
  return crypto.createHash("sha256").update(input).digest("hex");
}

function getPublicBaseUrl(req) {
  // Prefer explicit public URL for production deployments.
  if (ENV.PUBLIC_BACKEND_URL && ENV.PUBLIC_BACKEND_URL.trim()) {
    return ENV.PUBLIC_BACKEND_URL.trim().replace(/\/$/, "");
  }
  const proto = req.headers["x-forwarded-proto"] || req.protocol;
  return `${proto}://${req.get("host")}`;
}

async function ensureVerificationToken(user) {
  // If an unexpired token already exists, reuse it.
  if (
    user.emailVerificationTokenHash &&
    user.emailVerificationExpiresAt &&
    user.emailVerificationExpiresAt.getTime() > Date.now()
  ) {
    return null; // no new raw token
  }

  const rawToken = crypto.randomBytes(TOKEN_BYTES).toString("hex");
  user.emailVerificationTokenHash = sha256Hex(rawToken);
  user.emailVerificationExpiresAt = new Date(Date.now() + TOKEN_TTL_HOURS * 60 * 60 * 1000);
  return rawToken;
}

function canResend(user) {
  if (!user.emailVerificationLastSentAt) return true;
  const deltaMs = Date.now() - user.emailVerificationLastSentAt.getTime();
  return deltaMs >= RESEND_COOLDOWN_SECONDS * 1000;
}

export async function sendVerificationEmailForUser({ user, req, forceNewToken = false }) {
  if (user.isEmailVerified) {
    return { sent: false, reason: "already_verified" };
  }

  if (!forceNewToken) {
    const ok = canResend(user);
    if (!ok) {
      return { sent: false, reason: "cooldown" };
    }
  }

  let rawToken = null;
  if (forceNewToken) {
    rawToken = crypto.randomBytes(TOKEN_BYTES).toString("hex");
    user.emailVerificationTokenHash = sha256Hex(rawToken);
    user.emailVerificationExpiresAt = new Date(Date.now() + TOKEN_TTL_HOURS * 60 * 60 * 1000);
  } else {
    rawToken = await ensureVerificationToken(user);
  }

  // If we reused an existing token, we still need *some* token for the email.
  // In that case, forceNewToken should have been true; otherwise we can’t reconstruct.
  // So if ensureVerificationToken returned null, we generate a new one.
  if (!rawToken) {
    rawToken = crypto.randomBytes(TOKEN_BYTES).toString("hex");
    user.emailVerificationTokenHash = sha256Hex(rawToken);
    user.emailVerificationExpiresAt = new Date(Date.now() + TOKEN_TTL_HOURS * 60 * 60 * 1000);
  }

  user.emailVerificationLastSentAt = new Date();
  await user.save();

  const baseUrl = getPublicBaseUrl(req);
  const verifyUrl = `${baseUrl}/api/v1/auth/verify-email?token=${encodeURIComponent(rawToken)}`;

  const template = buildVerifyEmailTemplate({
    username: user.username,
    verifyUrl,
    expiresInHours: TOKEN_TTL_HOURS,
  });

  await sendEmail({
    to: user.email,
    subject: template.subject,
    html: template.html,
    text: template.text,
  });

  return { sent: true };
}

export async function verifyEmailHandler(req, res) {
  try {
    const token = req.query.token || req.body?.token;

    if (!token || typeof token !== "string") {
      return res.status(400).json({
        success: false,
        message: "Verification token is required",
      });
    }

    const tokenHash = sha256Hex(token);

    const user = await User.findOne({
      emailVerificationTokenHash: tokenHash,
      emailVerificationExpiresAt: { $gt: new Date() },
    });

    if (!user) {
      const acceptsHtml = (req.headers.accept || "").includes("text/html");
      if (acceptsHtml) {
        return res
          .status(400)
          .send(
            buildHtmlPage({
              title: "AgriCare — Verification failed",
              message: "This verification link is invalid or expired. Please request a new one from the app.",
              ok: false,
            })
          );
      }

      return res.status(400).json({
        success: false,
        message: "Verification link is invalid or expired",
      });
    }

    user.isEmailVerified = true;
    user.emailVerifiedAt = new Date();
    user.emailVerificationTokenHash = null;
    user.emailVerificationExpiresAt = null;
    await user.save();

    const acceptsHtml = (req.headers.accept || "").includes("text/html");
    if (acceptsHtml) {
      return res
        .status(200)
        .send(
          buildHtmlPage({
            title: "AgriCare — Email verified",
            message: "Your email is verified. You can now return to the AgriCare app and log in.",
            ok: true,
          })
        );
    }

    return res.status(200).json({
      success: true,
      message: "Email verified successfully. You can now login.",
    });
  } catch (error) {
    console.error("Verify email error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to verify email",
    });
  }
}

export async function resendVerificationEmailHandler(req, res) {
  try {
    const rawEmail = req.body?.email;
    const emailRes = validateEmail(rawEmail);
    if (!emailRes.ok) {
      return res.status(400).json({
        success: false,
        message: emailRes.message,
        errors: [{ field: "email", message: emailRes.message }],
      });
    }

    const email = emailRes.email;

    const user = await User.findOne({ email });

    // Avoid account enumeration.
    if (!user) {
      return res.status(200).json({
        success: true,
        message: "If an account exists for this email, a verification link has been sent.",
      });
    }

    if (user.isEmailVerified) {
      return res.status(200).json({
        success: true,
        message: "Email is already verified. Please login.",
      });
    }

    if (!canResend(user)) {
      return res.status(429).json({
        success: false,
        message: `Please wait ${RESEND_COOLDOWN_SECONDS} seconds before requesting another email.`,
      });
    }

    await sendVerificationEmailForUser({ user, req, forceNewToken: true });

    return res.status(200).json({
      success: true,
      message: "Verification email sent. Please check your inbox.",
    });
  } catch (error) {
    console.error("Resend verification email error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to send verification email",
    });
  }
}

function buildHtmlPage({ title, message, ok }) {
  const accent = ok ? "#198754" : "#dc3545";

  return `<!doctype html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width,initial-scale=1" />
      <title>${escapeHtml(title)}</title>
    </head>
    <body style="margin:0;background:#f6f9fc;font-family:Arial,Helvetica,sans-serif;">
      <div style="max-width:640px;margin:0 auto;padding:28px 16px;">
        <div style="background:#ffffff;border:1px solid #e8eef5;border-radius:14px;overflow:hidden;">
          <div style="padding:18px 20px;background:#0f5132;color:#ffffff;">
            <div style="font-weight:800;font-size:18px;">AgriCare</div>
          </div>
          <div style="padding:20px;">
            <div style="font-weight:800;font-size:18px;color:#111827;">${escapeHtml(title)}</div>
            <div style="margin-top:12px;color:#374151;font-size:14px;line-height:1.6;">${escapeHtml(
              message
            )}</div>
            <div style="margin-top:16px;height:3px;background:${accent};border-radius:999px;"></div>
            <div style="margin-top:14px;color:#6b7280;font-size:12px;">You can close this tab now.</div>
          </div>
        </div>
      </div>
    </body>
  </html>`;
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
