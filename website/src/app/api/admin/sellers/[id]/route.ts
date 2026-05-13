import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backendProxy";

export const runtime = "nodejs";

export async function PUT(
  req: Request,
  ctx: { params: Promise<{ id: string }> },
) {
  const { id } = await ctx.params;
  const body = (await req.json().catch(() => null)) as
    | { status?: "active" | "disabled"; name?: string; email?: string }
    | null;

  if (body?.name !== undefined || body?.email !== undefined) {
    const res = await backendFetch(`/api/v1/auth/admin/sellers/${id}`, {
      method: "PUT",
      body: JSON.stringify({
        username: body?.name,
        email: body?.email,
      }),
    });
    const j = (await res.json().catch(() => null)) as any;
    if (!res.ok) {
      return NextResponse.json(
        { ok: false, error: j?.message ?? "Update failed" },
        { status: res.status },
      );
    }
    return NextResponse.json({ ok: true });
  }

  if (body?.status === "disabled") {
    const res = await backendFetch(`/api/v1/auth/admin/sellers/${id}/disable`, {
      method: "PUT",
    });
    const j = (await res.json().catch(() => null)) as any;
    if (!res.ok) {
      return NextResponse.json(
        { ok: false, error: j?.message ?? "Disable failed" },
        { status: res.status },
      );
    }
    return NextResponse.json({ ok: true });
  }

  if (body?.status === "active") {
    const res = await backendFetch(`/api/v1/auth/admin/sellers/${id}/enable`, {
      method: "PUT",
    });
    const j = (await res.json().catch(() => null)) as any;
    if (!res.ok) {
      return NextResponse.json(
        { ok: false, error: j?.message ?? "Enable failed" },
        { status: res.status },
      );
    }
    return NextResponse.json({ ok: true });
  }

  return NextResponse.json(
    { ok: false, error: "Only status updates are supported." },
    { status: 400 },
  );
}

export async function DELETE(
  _req: Request,
  ctx: { params: Promise<{ id: string }> },
) {
  const { id } = await ctx.params;
  const res = await backendFetch(`/api/v1/auth/admin/sellers/${id}`, {
    method: "DELETE",
  });
  const j = (await res.json().catch(() => null)) as any;
  if (!res.ok) {
    return NextResponse.json(
      { ok: false, error: j?.message ?? "Delete failed" },
      { status: res.status },
    );
  }
  return NextResponse.json({ ok: true });
}

