import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backendProxy";

export const runtime = "nodejs";

export async function GET() {
  const res = await backendFetch("/api/v1/auth/check");
  const j = (await res.json().catch(() => null)) as any;
  if (!res.ok) {
    return NextResponse.json(
      { ok: false, error: j?.message ?? "Unauthorized" },
      { status: res.status },
    );
  }
  const u = j?.user;
  return NextResponse.json({
    name: u?.username ?? "",
    phone: "", // backend user model doesn't store phone; keep placeholder
    email: u?.email ?? "",
  });
}

export async function PUT(req: Request) {
  const body = (await req.json().catch(() => null)) as
    | Partial<{ name: string; phone: string; email: string }>
    | null;

  const name = (body?.name ?? "").toString().trim();
  const email = (body?.email ?? "").toString().trim();

  const res = await backendFetch("/api/v1/auth/admin/profile", {
    method: "PUT",
    body: JSON.stringify({ username: name, email }),
  });
  const j = (await res.json().catch(() => null)) as any;
  if (!res.ok) {
    return NextResponse.json(
      { ok: false, error: j?.message ?? "Update failed" },
      { status: res.status },
    );
  }

  const u = j?.user;
  return NextResponse.json({
    name: u?.username ?? name,
    phone: body?.phone ?? "",
    email: u?.email ?? email,
  });
}

