import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backendProxy";

export const runtime = "nodejs";

export async function GET(
  _req: Request,
  ctx: { params: Promise<{ roomId: string }> },
) {
  const { roomId } = await ctx.params;
  const res = await backendFetch(`/api/v1/chat/admin/room/${roomId}/messages`);
  const j = (await res.json().catch(() => null)) as any;
  if (!res.ok) {
    return NextResponse.json(
      { ok: false, error: j?.message ?? "Failed to fetch messages" },
      { status: res.status },
    );
  }
  const messages = Array.isArray(j)
    ? j
    : (j?.messages ?? j?.data?.messages ?? j?.data ?? []);
  return NextResponse.json({ messages });
}

