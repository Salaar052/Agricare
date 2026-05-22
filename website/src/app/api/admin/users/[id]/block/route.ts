import { NextResponse } from "next/server";

import { backendFetch } from "@/lib/backendProxy";



export const runtime = "nodejs";



export async function DELETE(

  _req: Request,

  ctx: { params: Promise<{ id: string }> },

) {

  const { id } = await ctx.params;

  const res = await backendFetch(`/api/v1/auth/admin/users/${id}/block`, {

    method: "DELETE",

  });

  const j = (await res.json().catch(() => null)) as any;

  if (!res.ok) {

    return NextResponse.json(

      { ok: false, error: j?.message ?? j?.error ?? "Block failed" },

      { status: res.status },

    );

  }

  return NextResponse.json({ ok: true, ...j });

}


