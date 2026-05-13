import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backendProxy";

export const runtime = "nodejs";

export async function GET() {
  const res = await backendFetch("/api/v1/marketplace/admin/all-listings?status=all&page=1&limit=100");
  const j = (await res.json().catch(() => null)) as any;
  if (!res.ok) {
    return NextResponse.json(
      { ok: false, error: j?.message ?? "Failed to fetch listings" },
      { status: res.status },
    );
  }
  const items = (j?.data?.items ?? j?.items ?? []) as any[];
  return NextResponse.json(
    items.map((it) => ({
      id: it._id,
      sellerId: it?.sellerId?._id ?? it?.sellerId ?? "",
      title: it.title,
      price: it.price,
      status: it.status,
      createdAt: it.createdAt,
      description: it.description ?? "",
      images: Array.isArray(it.images)
        ? it.images
            .map((img: any) => img?.url ?? img?.secure_url ?? img)
            .filter(Boolean)
        : [],
      rejectionReason: it.rejectionReason ?? null,
      sellerShopName: it?.sellerId?.shopName ?? null,
      posterEmail: it?.userId?.email ?? null,
    })),
  );
}

