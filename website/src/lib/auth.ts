import { SignJWT, jwtVerify } from "jose";

const COOKIE_NAME = "agricare_admin";

function getSecret() {
  const secret = process.env.AUTH_SECRET ?? "";
  if (!secret) {
    throw new Error(
      "Missing AUTH_SECRET. Add it to website/.env.local (see .env.local.example).",
    );
  }
  return new TextEncoder().encode(secret);
}

export type AdminSession = {
  email: string;
  role: "super_admin";
};

export function getSessionCookieName() {
  return COOKIE_NAME;
}

export async function signAdminSession(session: AdminSession) {
  return await new SignJWT(session)
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setExpirationTime("7d")
    .sign(getSecret());
}

export async function verifyAdminSession(token: string) {
  const { payload } = await jwtVerify(token, getSecret());
  const email = payload.email;
  const role = payload.role;

  if (typeof email !== "string" || role !== "super_admin") {
    throw new Error("Invalid session");
  }

  return { email, role } satisfies AdminSession;
}

