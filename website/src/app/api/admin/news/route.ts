import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backendProxy";

export const runtime = "nodejs";

export async function GET() {
  const res = await backendFetch("/api/v1/news?page=1&limit=50");
  const j = (await res.json().catch(() => null)) as any;
  if (!res.ok) {
    return NextResponse.json(
      { ok: false, error: j?.message ?? "Failed to fetch news" },
      { status: res.status },
    );
  }
  const items = (j?.data?.items ?? []) as any[];
  return NextResponse.json(
    items.map((n) => ({
      id: n._id,
      title: n?.headline?.en || n?.headline?.ur || "",
      body: n?.description?.en || n?.description?.ur || "",
      createdAt: n?.createdAt,
      updatedAt: n?.updatedAt,
      language: n?.language ?? "both",
      images: Array.isArray(n?.images)
        ? n.images
            .map((img: any) => img?.url ?? img?.secure_url ?? img)
            .filter(Boolean)
        : [],
    })),
  );
}

export async function POST(req: Request) {
  const form = await req.formData();
  const title = form.get("title")?.toString().trim() ?? "";
  const text = form.get("body")?.toString().trim() ?? "";
  const isPublished = true;
  const language = (form.get("language")?.toString() ?? "both") as
    | "both"
    | "en"
    | "ur";
  const out = new FormData();
  out.set("headlineEn", title);
  out.set("descriptionEn", text);
  out.set("isPublished", String(isPublished));
  out.set("language", language);
  for (const img of form.getAll("images")) {
    if (img instanceof File && img.size > 0) {
      out.append("images", img);
    }
  }

  const res = await backendFetch("/api/v1/news", {
    method: "POST",
    body: out,
  });
  const j = (await res.json().catch(() => null)) as any;
  if (!res.ok) {
    return NextResponse.json(
      { ok: false, error: j?.message ?? "Create failed" },
      { status: res.status },
    );
  }
  return NextResponse.json({ ok: true, id: j?.data?.news?._id ?? null });
}

