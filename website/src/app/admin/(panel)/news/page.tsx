"use client";

import { useEffect, useState } from "react";

type NewsItem = {
  id: string;
  title: string;
  body: string;
  createdAt: string;
  updatedAt: string;
  images?: string[];
};

export default function NewsPage() {
  const [items, setItems] = useState<NewsItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [files, setFiles] = useState<FileList | null>(null);

  async function refresh() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/news", { cache: "no-store" });
      const j = (await res.json().catch(() => null)) as
        | NewsItem[]
        | { error?: string }
        | null;
      if (!res.ok) {
        setItems([]);
        setError((j as { error?: string } | null)?.error ?? "Failed to load news");
        return;
      }
      setItems(Array.isArray(j) ? j : []);
    } catch {
      setError("Failed to load news");
      setItems([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
  }, []);

  async function createItem(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    if (!files || files.length === 0) {
      setError("Please choose at least one picture for this news item.");
      return;
    }
    const form = new FormData();
    form.set("title", title);
    form.set("body", body);
    if (files) {
      for (const file of Array.from(files)) {
        form.append("images", file);
      }
    }
    const res = await fetch("/api/admin/news", {
      method: "POST",
      body: form,
    });
    if (!res.ok) {
      const j = (await res.json().catch(() => null)) as any;
      setError(j?.error ?? "Create failed");
      return;
    }
    setTitle("");
    setBody("");
    setFiles(null);
    await refresh();
  }

  async function updateItem(id: string, patch: { title: string; body: string }) {
    setError(null);
    const res = await fetch(`/api/admin/news/${id}`, {
      method: "PUT",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(patch),
    });
    if (!res.ok) {
      const j = (await res.json().catch(() => null)) as any;
      setError(j?.error ?? "Update failed (backend does not support editing yet)");
      return;
    }
    await refresh();
  }

  async function deleteItem(id: string) {
    if (!confirm("Remove this news/announcement?")) return;
    setError(null);
    const res = await fetch(`/api/admin/news/${id}`, { method: "DELETE" });
    if (!res.ok) setError("Delete failed");
    await refresh();
  }

  return (
    <div className="space-y-5">
      <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
        <h1 className="text-xl font-semibold tracking-tight">
          Content & news management
        </h1>
        <p className="mt-2 text-sm leading-7 text-zinc-700">
          Add news or announcement
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
          <div className="text-sm font-semibold">Create announcement</div>
          <form onSubmit={createItem} className="mt-4 space-y-3">
            <input
              className="w-full rounded-2xl border border-black/10 bg-white px-4 py-3 text-sm outline-none focus:border-emerald-600"
              placeholder="Title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
            />
            <textarea
              className="min-h-28 w-full rounded-2xl border border-black/10 bg-white px-4 py-3 text-sm outline-none focus:border-emerald-600"
              placeholder="Body"
              value={body}
              onChange={(e) => setBody(e.target.value)}
            />
            <label className="block text-sm text-zinc-700">
              Picture (required)
              <input
                type="file"
                multiple
                required
                accept="image/*"
                onChange={(e) => setFiles(e.target.files)}
                className="mt-2 block w-full rounded-2xl border border-black/10 bg-white px-3 py-2 text-sm"
              />
            </label>
            <button className="inline-flex h-10 items-center justify-center rounded-full bg-emerald-600 px-4 text-sm font-semibold text-white hover:bg-emerald-700">
              Post
            </button>
          </form>
        </div>

        <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
          <div className="text-sm font-semibold">Tips</div>
          <div className="mt-3 space-y-2 text-sm leading-7 text-zinc-700">
            <div>
              New posts go live for app users as soon as they are created. Use{" "}
              <span className="font-semibold">Remove</span> to delete an item.
            </div>
            <div>Upload at least one image with each announcement.</div>
          </div>
        </div>
      </div>

      <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
        <div className="flex items-center justify-between">
          <div className="text-sm font-semibold">News feed</div>
          <button
            onClick={refresh}
            className="rounded-full border border-black/10 bg-white px-4 py-2 text-sm font-semibold hover:bg-black/5"
          >
            Refresh
          </button>
        </div>

        {error ? (
          <div className="mt-4 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
            {error}
          </div>
        ) : null}

        {loading ? (
          <div className="mt-4 text-sm text-zinc-600">Loading...</div>
        ) : (
          <div className="mt-4 space-y-3">
            {items.map((x) => (
              <div
                key={x.id}
                className="rounded-3xl border border-black/5 bg-zinc-50 p-5"
              >
                <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                  <div className="min-w-0">
                    <div className="truncate text-sm font-semibold">
                      {x.title}
                    </div>
                    <div className="mt-1 text-sm leading-7 text-zinc-700">
                      {x.body || <span className="text-zinc-500">(no body)</span>}
                    </div>
                    <div className="mt-2 text-xs text-zinc-600">
                      Updated: {new Date(x.updatedAt).toLocaleString()}
                    </div>
                    {x.images?.[0] ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={x.images[0]}
                        alt={x.title}
                        className="mt-3 h-20 w-20 rounded-xl object-cover"
                      />
                    ) : null}
                  </div>
                  <div className="flex shrink-0 items-center gap-2">
                    <button
                      onClick={() => {
                        const t = prompt("Edit title", x.title) ?? x.title;
                        const b = prompt("Edit body", x.body) ?? x.body;
                        updateItem(x.id, { title: t, body: b });
                      }}
                      className="rounded-full border border-black/10 bg-white px-3 py-1.5 text-xs font-semibold hover:bg-black/5"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => deleteItem(x.id)}
                      className="rounded-full border border-red-200 bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-800 hover:bg-red-100"
                    >
                      Remove
                    </button>
                  </div>
                </div>
              </div>
            ))}
            {items.length === 0 ? (
              <div className="text-sm text-zinc-600">No news yet.</div>
            ) : null}
          </div>
        )}
      </div>
    </div>
  );
}

