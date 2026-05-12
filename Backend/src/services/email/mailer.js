import nodemailer from "nodemailer";
import ENV from "../../utils/ENV.js";

function toBool(value) {
  if (value === true || value === false) return value;
  if (typeof value !== "string") return undefined;
  const normalized = value.trim().toLowerCase();
  if (["1", "true", "yes", "y"].includes(normalized)) return true;
  if (["0", "false", "no", "n"].includes(normalized)) return false;
  return undefined;
}

export function getEmailFrom() {
  if (ENV.EMAIL_FROM && ENV.EMAIL_FROM.trim()) return ENV.EMAIL_FROM.trim();
  if (ENV.EMAIL_USER && ENV.EMAIL_USER.trim()) return `AgriCare <${ENV.EMAIL_USER.trim()}>`;
  return "AgriCare <no-reply@agricare.local>";
}

export function createTransporter() {
  const hasHost = !!ENV.SMTP_HOST;
  const hasService = !!ENV.SMTP_SERVICE;

  if (!ENV.EMAIL_USER || !ENV.EMAIL_PASSWORD) {
    throw new Error(
      "Missing EMAIL_USER/EMAIL_PASSWORD for nodemailer. Configure SMTP credentials in Backend/.env"
    );
  }

  if (hasHost) {
    const port = ENV.SMTP_PORT ? Number(ENV.SMTP_PORT) : 587;
    const secure = toBool(ENV.SMTP_SECURE) ?? port === 465;

    return nodemailer.createTransport({
      host: ENV.SMTP_HOST,
      port,
      secure,
      auth: {
        user: ENV.EMAIL_USER,
        pass: ENV.EMAIL_PASSWORD,
      },
    });
  }

  // Convenience for Gmail or other service-based SMTP.
  return nodemailer.createTransport({
    service: hasService ? ENV.SMTP_SERVICE : "gmail",
    auth: {
      user: ENV.EMAIL_USER,
      pass: ENV.EMAIL_PASSWORD,
    },
  });
}

export async function sendEmail({ to, subject, html, text }) {
  const transporter = createTransporter();
  const from = getEmailFrom();

  const info = await transporter.sendMail({
    from,
    to,
    subject,
    html,
    text,
  });

  return info;
}
