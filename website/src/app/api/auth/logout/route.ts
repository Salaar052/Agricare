import { NextResponse } from "next/server";
import { cookies } from "next/headers";

export const runtime = "nodejs";

export async function POST() {
  const base = (process.env.BACKEND_URL ?? "https://agricare-t3ou.onrender.com").replace(/\/$/, "");
  const jar = await cookies();
  const token = jar.get("agricare_admin_token")?.value;
  if (token) {
    await fetch(`${base}/api/v1/auth/logout`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
      cache: "no-store",
    }).catch(() => null);
  }

  jar.set("agricare_admin_token", "", {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 0,
  });
  return NextResponse.json({ ok: true });
}

