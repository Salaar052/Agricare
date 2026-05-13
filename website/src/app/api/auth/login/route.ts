import { NextResponse } from "next/server";
import { cookies } from "next/headers";

export const runtime = "nodejs";

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as
    | { email?: string; password?: string }
    | null;

  const email = body?.email?.trim();
  const password = body?.password ?? "";

  const expectedEmail = (process.env.ADMIN_EMAIL ?? "").trim();
  const expectedPassword = process.env.ADMIN_PASSWORD ?? "";
  if (!email || !expectedEmail || !expectedPassword) {
    return NextResponse.json(
      { ok: false, error: "Server is not configured for admin login." },
      { status: 500 },
    );
  }
  if (email !== expectedEmail || password !== expectedPassword) {
    return NextResponse.json({ ok: false, error: "Invalid credentials" }, { status: 401 });
  }

  const base = (process.env.BACKEND_URL ?? "http://localhost:5000").replace(/\/$/, "");
  const res = await fetch(`${base}/api/v1/auth/login`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email, password }),
    cache: "no-store",
  });
  const json = (await res.json().catch(() => null)) as any;
  if (!res.ok || !json?.token) {
    return NextResponse.json(
      { ok: false, error: json?.message ?? "Backend login failed" },
      { status: 401 },
    );
  }
  const token = String(json.token);

  const jar = await cookies();
  jar.set("agricare_admin_token", token, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 60 * 60 * 24 * 7,
  });

  return NextResponse.json({ ok: true });
}

