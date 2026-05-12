import crypto from "crypto";
import bcrypt from "bcrypt";
import User from "../../models/auth/user.js";
import ENV from "../../utils/ENV.js";
import { sendEmail } from "../../services/email/mailer.js";
import { buildResetPasswordTemplate } from "../../services/email/templates/resetPassword.template.js";
import { validateEmail, validateSignupPassword } from "../../utils/authValidator.js";

const TOKEN_BYTES = 32;
const TOKEN_TTL_MINUTES = 30;
const RESEND_COOLDOWN_SECONDS = 60;

function sha256Hex(input) {
  return crypto.createHash("sha256").update(input).digest("hex");
}

function getPublicBaseUrl(req) {
  if (ENV.PUBLIC_BACKEND_URL && ENV.PUBLIC_BACKEND_URL.trim()) {
    return ENV.PUBLIC_BACKEND_URL.trim().replace(/\/$/, "");
  }
  const proto = req.headers["x-forwarded-proto"] || req.protocol;
  return `${proto}://${req.get("host")}`;
}

function canResend(user) {
  if (!user.passwordResetLastSentAt) return true;
  const deltaMs = Date.now() - user.passwordResetLastSentAt.getTime();
  return deltaMs >= RESEND_COOLDOWN_SECONDS * 1000;
}

async function createResetToken(user) {
  const rawToken = crypto.randomBytes(TOKEN_BYTES).toString("hex");
  user.passwordResetTokenHash = sha256Hex(rawToken);
  user.passwordResetExpiresAt = new Date(Date.now() + TOKEN_TTL_MINUTES * 60 * 1000);
  user.passwordResetLastSentAt = new Date();
  await user.save();
  return rawToken;
}

export async function requestPasswordResetHandler(req, res) {
  try {
    const emailRes = validateEmail(req.body?.email);
    if (!emailRes.ok) {
      return res.status(400).json({
        success: false,
        message: emailRes.message,
        errors: [{ field: "email", message: emailRes.message }],
      });
    }

    const email = emailRes.email;

    const user = await User.findOne({ email });

    // Avoid account enumeration
    if (!user) {
      return res.status(200).json({
        success: true,
        message: "If an account exists for this email, a reset link has been sent.",
      });
    }

    if (!canResend(user)) {
      return res.status(429).json({
        success: false,
        message: `Please wait ${RESEND_COOLDOWN_SECONDS} seconds before requesting another email.`,
      });
    }

    const rawToken = await createResetToken(user);
    const baseUrl = getPublicBaseUrl(req);
    const resetUrl = `${baseUrl}/api/v1/auth/reset-password?token=${encodeURIComponent(rawToken)}`;

    const template = buildResetPasswordTemplate({
      username: user.username,
      resetUrl,
      expiresInMinutes: TOKEN_TTL_MINUTES,
    });

    await sendEmail({
      to: user.email,
      subject: template.subject,
      html: template.html,
      text: template.text,
    });

    return res.status(200).json({
      success: true,
      message: "If an account exists for this email, a reset link has been sent.",
    });
  } catch (error) {
    console.error("Request password reset error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to request password reset",
    });
  }
}

export async function resetPasswordHandler(req, res) {
  try {
    const token = req.query.token || req.body?.token;
    const newPassword = req.body?.newPassword;

    if (!token || typeof token !== "string") {
      return res.status(400).json({
        success: false,
        message: "Reset token is required",
      });
    }

    // GET should render a simple reset page
    if (req.method === "GET") {
      return res.status(200).send(buildResetHtmlPage({ token }));
    }

    const passwordRes = validateSignupPassword(newPassword);
    if (!passwordRes.ok) {
      return res.status(400).json({
        success: false,
        message: passwordRes.message,
        errors: [{ field: "newPassword", message: passwordRes.message }],
      });
    }

    const tokenHash = sha256Hex(token);

    const user = await User.findOne({
      passwordResetTokenHash: tokenHash,
      passwordResetExpiresAt: { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: "Reset link is invalid or expired",
      });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(passwordRes.password, salt);

    user.password = hashedPassword;
    user.passwordResetTokenHash = null;
    user.passwordResetExpiresAt = null;
    await user.save();

    return res.status(200).json({
      success: true,
      message: "Password reset successful. You can now login.",
    });
  } catch (error) {
    console.error("Reset password error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to reset password",
    });
  }
}

function buildResetHtmlPage({ token }) {
  return `<!doctype html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width,initial-scale=1" />
      <title>AgriCare — Reset Password</title>
    </head>
    <body style="margin:0;background:#f6f9fc;font-family:Arial,Helvetica,sans-serif;">
      <div style="max-width:640px;margin:0 auto;padding:28px 16px;">
        <div style="background:#ffffff;border:1px solid #e8eef5;border-radius:14px;overflow:hidden;">
          <div style="padding:18px 20px;background:#0f5132;color:#ffffff;">
            <div style="font-weight:800;font-size:18px;">AgriCare</div>
          </div>
          <div style="padding:20px;">
            <div style="font-weight:800;font-size:18px;color:#111827;">Reset your password</div>
            <div style="margin-top:10px;color:#374151;font-size:14px;line-height:1.6;">Enter a new password below.</div>

            <form id="resetForm" style="margin-top:16px;">
              <input type="hidden" name="token" value="${escapeHtml(token)}" />
              <label style="display:block;font-size:12px;color:#6b7280;margin-bottom:6px;">New password</label>
              <input type="password" name="newPassword" minlength="6" required
                style="width:100%;padding:12px;border:1px solid #e5e7eb;border-radius:10px;font-size:14px;" />

              <button type="submit" style="margin-top:14px;width:100%;padding:12px 18px;border-radius:10px;border:none;background:#198754;color:#ffffff;font-weight:800;font-size:14px;cursor:pointer;">
                Reset Password
              </button>
            </form>

            <div id="status" style="margin-top:14px;font-size:13px;color:#374151;"></div>
          </div>
        </div>
      </div>

      <script>
        const form = document.getElementById('resetForm');
        const statusEl = document.getElementById('status');

        form.addEventListener('submit', async (e) => {
          e.preventDefault();
          statusEl.textContent = 'Resetting...';

          const formData = new FormData(form);
          const token = formData.get('token');
          const newPassword = formData.get('newPassword');

          try {
            const res = await fetch('/api/v1/auth/reset-password', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ token, newPassword })
            });

            const data = await res.json();
            if (res.ok && data.success) {
              statusEl.style.color = '#198754';
              statusEl.textContent = data.message || 'Password reset successful. You can close this tab and login.';
            } else {
              statusEl.style.color = '#dc3545';
              statusEl.textContent = data.message || 'Reset failed.';
            }
          } catch (err) {
            statusEl.style.color = '#dc3545';
            statusEl.textContent = 'Network error. Please try again.';
          }
        });
      </script>
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
