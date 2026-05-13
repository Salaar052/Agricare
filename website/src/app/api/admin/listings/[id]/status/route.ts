import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backendProxy";

export const runtime = "nodejs";

export async function PUT(
  req: Request,
  ctx: { params: Promise<{ id: string }> },
) {
  const { id } = await ctx.params;
  const body = (await req.json().catch(() => null)) as
    | { status?: "pending" | "approved" | "rejected"; rejectionReason?: string }
    | null;

  const status = body?.status;
  if (status !== "approved" && status !== "rejected" && status !== "pending") {
    return NextResponse.json(
      { ok: false, error: "Invalid status" },
      { status: 400 },
    );
  }

  if (status === "approved") {
    const res = await backendFetch(`/api/v1/marketplace/admin/items/${id}/approve`, {
      method: "PUT",
    });
    const j = (await res.json().catch(() => null)) as any;
    if (!res.ok) {
      return NextResponse.json(
        { ok: false, error: j?.message ?? "Approve failed" },
        { status: res.status },
      );
    }
    return NextResponse.json({ ok: true });
  }

  if (status === "rejected") {
    const res = await backendFetch(`/api/v1/marketplace/admin/items/${id}/reject`, {
      method: "PUT",
      body: JSON.stringify({ rejectionReason: body?.rejectionReason ?? "" }),
    });
    const j = (await res.json().catch(() => null)) as any;
    if (!res.ok) {
      return NextResponse.json(
        { ok: false, error: j?.message ?? "Reject failed" },
        { status: res.status },
      );
    }
    return NextResponse.json({ ok: true });
  }

  // backend doesn't support resetting to pending via admin; keep as no-op
  return NextResponse.json(
    { ok: false, error: "Reset to pending is not supported by backend." },
    { status: 400 },
  );
}

