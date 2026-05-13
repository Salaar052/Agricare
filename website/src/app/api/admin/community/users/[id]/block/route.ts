import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backendProxy";

export const runtime = "nodejs";

export async function PUT(
  req: Request,
  ctx: { params: Promise<{ id: string }> },
) {
  const { id } = await ctx.params;
  const body = (await req.json().catch(() => null)) as { roomId?: string } | null;
  const roomId = (body?.roomId ?? "").toString().trim();
  if (!roomId) {
    return NextResponse.json({ ok: false, error: "roomId is required" }, { status: 400 });
  }

  // Implement "block" for moderation as removing user from the selected room.
  const res = await backendFetch(`/api/v1/chat/admin/room/${roomId}/members/${id}`, {
    method: "DELETE",
  });
  const j = (await res.json().catch(() => null)) as any;
  if (!res.ok) {
    return NextResponse.json(
      { ok: false, error: j?.message ?? j?.error ?? "Block failed" },
      { status: res.status },
    );
  }
  return NextResponse.json({ ok: true });
}

