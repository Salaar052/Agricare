import { NextResponse } from "next/server";

export const runtime = "nodejs";

/** Public news list (no auth). Proxies published items from the backend. */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const page = Math.max(1, Number(url.searchParams.get("page")) || 1);
  const limit = Math.min(50, Math.max(1, Number(url.searchParams.get("limit")) || 12));
  const base = (process.env.BACKEND_URL ?? "https://agricare-t3ou.onrender.com").replace(/\/$/, "");
  const res = await fetch(
    `${base}/api/v1/news?page=${page}&limit=${limit}`,
    { cache: "no-store" },
  );
  const j = (await res.json().catch(() => null)) as any;
  if (!res.ok) {
    return NextResponse.json(
      { ok: false, error: j?.message ?? "Failed to fetch news" },
      { status: res.status },
    );
  }
  const raw = (j?.data?.items ?? []) as any[];
  const items = raw.map((n) => {
    const images = Array.isArray(n?.images)
      ? n.images
          .map((img: any) => img?.url ?? img?.secure_url ?? "")
          .filter(Boolean)
      : [];
    return {
      id: String(n._id),
      title: n?.headline?.en || n?.headline?.ur || "",
      description: n?.description?.en || n?.description?.ur || "",
      images,
      imageUrl: images[0] ?? "",
    };
  });
  return NextResponse.json({ ok: true, items });
}
