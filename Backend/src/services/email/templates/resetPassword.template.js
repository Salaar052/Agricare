export function buildResetPasswordTemplate({
  username,
  resetUrl,
  expiresInMinutes,
}) {
  const safeName = (username || "Farmer").toString().trim() || "Farmer";

  const subject = "Reset your AgriCare password";

  const text = `Hi ${safeName},\n\nWe received a request to reset your AgriCare password.\n\nReset your password using this link:\n${resetUrl}\n\nThis link expires in ${expiresInMinutes} minute(s).\n\nIf you did not request this, you can ignore this email.\n\n— AgriCare Team`;

  const html = `
  <div style="margin:0;padding:0;background:#f6f9fc;font-family:Arial,Helvetica,sans-serif;">
    <div style="max-width:600px;margin:0 auto;padding:28px 16px;">
      <div style="background:#ffffff;border-radius:14px;overflow:hidden;border:1px solid #e8eef5;">
        <div style="padding:20px 22px;background:#0f5132;color:#ffffff;">
          <div style="font-size:18px;font-weight:700;letter-spacing:0.2px;">AgriCare</div>
          <div style="font-size:12px;opacity:0.9;margin-top:6px;">Password reset request</div>
        </div>

        <div style="padding:22px;">
          <div style="font-size:16px;color:#111827;font-weight:700;">Reset your password</div>
          <div style="margin-top:10px;font-size:14px;line-height:1.6;color:#374151;">
            Hi <b>${escapeHtml(safeName)}</b>,<br/>
            We received a request to reset your password. Click the button below to set a new password.
          </div>

          <div style="margin-top:18px;">
            <a href="${resetUrl}" style="display:inline-block;background:#198754;color:#ffffff;text-decoration:none;padding:12px 18px;border-radius:10px;font-weight:700;font-size:14px;">Reset Password</a>
          </div>

          <div style="margin-top:16px;font-size:12px;line-height:1.6;color:#6b7280;">
            This link expires in <b>${Number(expiresInMinutes)}</b> minute(s).<br/>
            If the button doesn’t work, copy and paste this URL into your browser:
            <div style="margin-top:8px;word-break:break-all;color:#111827;">${resetUrl}</div>
          </div>

          <div style="margin-top:18px;font-size:12px;line-height:1.6;color:#6b7280;">
            If you did not request a password reset, you can safely ignore this email.
          </div>
        </div>

        <div style="padding:14px 22px;background:#f9fafb;border-top:1px solid #eef2f7;color:#6b7280;font-size:12px;">
          © ${new Date().getFullYear()} AgriCare. All rights reserved.
        </div>
      </div>
    </div>
  </div>`;

  return { subject, html, text };
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
