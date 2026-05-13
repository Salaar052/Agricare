"use client";

import { useCallback, useEffect, useState } from "react";

type NewsCard = {
  id: string;
  title: string;
  description: string;
  images: string[];
  imageUrl: string;
};

export default function HomeNewsSection() {
  const [items, setItems] = useState<NewsCard[]>([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);
  const [open, setOpen] = useState<NewsCard | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setErr(null);
    try {
      const res = await fetch("/api/news?limit=8", { cache: "no-store" });
      const j = (await res.json().catch(() => null)) as
        | { ok?: boolean; items?: NewsCard[]; error?: string }
        | null;
      if (!res.ok || !j?.ok) {
        setErr(j?.error ?? "Could not load news");
        setItems([]);
        return;
      }
      setItems(Array.isArray(j.items) ? j.items : []);
    } catch {
      setErr("Could not load news");
      setItems([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  if (loading) {
    return (
      <section id="news" className="py-14">
        <h2 className="text-2xl font-semibold tracking-tight">Agricultural news</h2>
        <p className="mt-3 text-sm text-zinc-600">Loading…</p>
      </section>
    );
  }

  if (err || items.length === 0) {
    return null;
  }

  return (
    <section id="news" className="py-14">
      <div className="flex flex-col gap-3">
        <h2 className="text-2xl font-semibold tracking-tight">Agricultural news</h2>
        <p className="max-w-3xl text-zinc-700">
          Updates and announcements from AgriCare. Select an item to read more.
        </p>
      </div>

      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {items.map((n) => (
          <button
            key={n.id}
            type="button"
            onClick={() => setOpen(n)}
            className="group rounded-3xl border border-black/5 bg-white p-0 text-left shadow-sm transition hover:border-emerald-600/30 hover:shadow-md"
          >
            <div className="overflow-hidden rounded-t-3xl border-b border-black/5 bg-zinc-50">
              {n.imageUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={n.imageUrl}
                  alt=""
                  className="h-40 w-full object-cover transition duration-300 group-hover:scale-[1.02]"
                  loading="lazy"
                />
              ) : (
                <div className="flex h-40 items-center justify-center text-sm text-zinc-500">
                  No image
                </div>
              )}
            </div>
            <div className="p-5">
              <div className="line-clamp-2 text-sm font-semibold text-zinc-950">
                {n.title || "Untitled"}
              </div>
              <div className="mt-2 line-clamp-2 text-sm leading-7 text-zinc-600">
                {n.description || "—"}
              </div>
              <div className="mt-3 text-xs font-semibold text-emerald-700">
                Read more
              </div>
            </div>
          </button>
        ))}
      </div>

      {open ? (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
          role="dialog"
          aria-modal="true"
          aria-labelledby="news-dialog-title"
          onClick={() => setOpen(null)}
        >
          <div
            className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-3xl border border-black/10 bg-white shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="border-b border-black/5 bg-zinc-50">
              {open.imageUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={open.imageUrl}
                  alt=""
                  className="max-h-72 w-full object-contain"
                />
              ) : null}
            </div>
            <div className="p-6">
              <h3
                id="news-dialog-title"
                className="text-lg font-semibold tracking-tight text-zinc-950"
              >
                {open.title || "Untitled"}
              </h3>
              <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-zinc-700">
                {open.description || "—"}
              </p>
              <button
                type="button"
                className="mt-6 inline-flex h-10 items-center justify-center rounded-full bg-emerald-600 px-5 text-sm font-semibold text-white hover:bg-emerald-700"
                onClick={() => setOpen(null)}
              >
                Close
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </section>
  );
}
