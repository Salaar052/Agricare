import { NextResponse } from "next/server";

import { backendFetch } from "@/lib/backendProxy";



export const runtime = "nodejs";



export async function GET() {

  const res = await backendFetch("/api/v1/auth/admin/farmers");

  const j = (await res.json().catch(() => null)) as any;

  if (!res.ok) {

    return NextResponse.json(

      { ok: false, error: j?.message ?? "Failed to fetch users" },

      { status: res.status },

    );

  }



  const farmers = (j?.farmers ?? []) as any[];

  const users = farmers.map((f) => ({

    id: f._id,

    name: f.username,

    email: f.email,

    phone: "",

    role: f.isSeller ? "seller" : "user",

    status: f.isSeller ? (f.sellerIsActive ? "active" : "disabled") : "active",

    createdAt: f.createdAt,

  }));



  return NextResponse.json(users);

}



export async function POST(req: Request) {

  const body = (await req.json().catch(() => null)) as

    | { name?: string; email?: string; password?: string }

    | null;



  const name = (body?.name ?? "").toString().trim();

  const email = (body?.email ?? "").toString().trim();

  const password = (body?.password ?? "").toString();



  if (!name || !email || !password) {

    return NextResponse.json(

      { ok: false, error: "Name, email, and password are required." },

      { status: 400 },

    );

  }



  const res = await backendFetch("/api/v1/auth/signup", {

    method: "POST",

    body: JSON.stringify({ username: name, email, password }),

  });

  const j = (await res.json().catch(() => null)) as any;

  if (!res.ok) {

    return NextResponse.json(

      { ok: false, error: j?.message ?? "Signup failed" },

      { status: res.status },

    );

  }

  return NextResponse.json({ ok: true, userId: j?._id });

}


