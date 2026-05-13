import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backendProxy";

export const runtime = "nodejs";

export async function GET() {
  // Admin view: list rooms; UI will fetch messages per room if needed.
  const res = await backendFetch("/api/v1/chat/admin/rooms");
  const j = (await res.json().catch(() => null)) as any;
  if (!res.ok) {
    return NextResponse.json(
      { ok: false, error: j?.message ?? "Failed to fetch rooms" },
      { status: res.status },
    );
  }

  // Backend returns an array for this endpoint.
  const rooms = (Array.isArray(j)
    ? j
    : (j?.rooms ?? j?.data?.rooms ?? j?.data ?? [])) as any[];
  return NextResponse.json({ rooms });
}

