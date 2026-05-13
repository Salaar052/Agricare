import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backendProxy";

export const runtime = "nodejs";

export async function GET(
  _req: Request,
  ctx: { params: Promise<{ roomId: string }> },
) {
  const { roomId } = await ctx.params;
  const res = await backendFetch(`/api/v1/chat/admin/room/${roomId}/members`);
  const j = (await res.json().catch(() => null)) as any;
  if (!res.ok) {
    return NextResponse.json(
      { ok: false, error: j?.message ?? j?.error ?? "Failed to fetch members" },
      { status: res.status },
    );
  }
  return NextResponse.json(j);
}

