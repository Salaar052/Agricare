"use client";

import { useEffect, useMemo, useState } from "react";

type Listing = {
  id: string;
  sellerId: string;
  title: string;
  price: number;
  status: "pending" | "approved" | "rejected";
  createdAt: string;
  description?: string;
  images?: string[];
  rejectionReason?: string | null;
  sellerShopName?: string | null;
  posterEmail?: string | null;
};

export default function MarketplaceOversightPage() {
  const [items, setItems] = useState<Listing[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<"all" | Listing["status"]>("all");
  const [busyId, setBusyId] = useState<string | null>(null);

  const filtered = useMemo(() => {
    if (filter === "all") return items;
    return items.filter((x) => x.status === filter);
  }, [items, filter]);

  async function refresh() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/listings", { cache: "no-store" });
      const j = (await res.json().catch(() => null)) as
        | Listing[]
        | { error?: string }
        | null;
      if (!res.ok) {
        setItems([]);
        setError((j as { error?: string } | null)?.error ?? "Failed to load listings");
        return;
      }
      setItems(Array.isArray(j) ? j : []);
    } catch {
      setError("Failed to load listings");
      setItems([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
  }, []);

  async function parseError(res: Response) {
    const j = (await res.json().catch(() => null)) as { message?: string; error?: string } | null;
    return j?.message ?? j?.error ?? `Request failed (${res.status})`;
  }

  async function setStatus(id: string, status: Listing["status"]) {
    setBusyId(id);
    setError(null);
    try {
      let rejectionReason: string | undefined;
      if (status === "rejected") {
        const entered = window.prompt("Rejection reason (optional)", "");
        if (entered === null) {
          setBusyId(null);
          return;
        }
        rejectionReason = entered;
      }
      const res = await fetch(`/api/admin/listings/${id}/status`, {
        method: "PUT",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ status, rejectionReason }),
      });
      if (!res.ok) setError(await parseError(res));
      await refresh();
    } finally {
      setBusyId(null);
    }
  }

  async function deleteListing(id: string) {
    if (!window.confirm("Permanently delete this listing from the marketplace?")) return;
    setBusyId(id);
    setError(null);
    try {
      const res = await fetch(`/api/admin/listings/${id}`, { method: "DELETE" });
      if (!res.ok) setError(await parseError(res));
      await refresh();
    } finally {
      setBusyId(null);
    }
  }

  return (
    <div className="space-y-5">
      <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
        <h1 className="text-xl font-semibold tracking-tight">
          Marketplace oversight
        </h1>
        <p className="mt-2 text-sm leading-7 text-zinc-700">
          Approve, reject, or delete listings (including approved posts).
        </p>
      </div>

      <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="text-sm font-semibold">Listings</div>
          <div className="flex items-center gap-2">
            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value as typeof filter)}
              className="rounded-2xl border border-black/10 bg-white px-3 py-2 text-sm"
            >
              <option value="all">All</option>
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
            </select>
            <button
              onClick={refresh}
              className="rounded-full border border-black/10 bg-white px-4 py-2 text-sm font-semibold hover:bg-black/5"
            >
              Refresh
            </button>
          </div>
        </div>

        {error ? (
          <div className="mt-4 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
            {error}
          </div>
        ) : null}

        {loading ? (
          <div className="mt-4 text-sm text-zinc-600">Loading...</div>
        ) : (
          <div className="mt-4 overflow-x-auto">
            <table className="w-full min-w-[900px] text-left text-sm">
              <thead className="text-xs text-zinc-600">
                <tr>
                  <th className="py-2">Title</th>
                  <th>Seller</th>
                  <th>Price</th>
                  <th>Status</th>
                  <th className="text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="align-top">
                {filtered.map((x) => (
                  <tr key={x.id} className="border-t border-black/5">
                    <td className="py-3 font-medium">
                      <div>{x.title}</div>
                      <details className="mt-2">
                        <summary className="cursor-pointer text-xs font-medium text-emerald-700">
                          View details
                        </summary>
                        <div className="mt-2 rounded-2xl border border-black/5 bg-zinc-50 p-3 text-xs text-zinc-700">
                          <div>
                            {x.description || (
                              <span className="text-zinc-500">No description</span>
                            )}
                          </div>
                          {x.images?.[0] ? (
                            // eslint-disable-next-line @next/next/no-img-element
                            <img
                              src={x.images[0]}
                              alt={x.title}
                              className="mt-2 h-24 w-24 rounded-xl object-cover"
                            />
                          ) : (
                            <div className="mt-2 text-zinc-500">No image</div>
                          )}
                        </div>
                      </details>
                    </td>
                    <td className="text-zinc-700">
                      {x.sellerShopName ?? x.sellerId}
                      {x.posterEmail ? (
                        <div className="text-xs text-zinc-500">{x.posterEmail}</div>
                      ) : null}
                      {x.rejectionReason ? (
                        <div className="text-xs text-red-700">
                          Reason: {x.rejectionReason}
                        </div>
                      ) : null}
                    </td>
                    <td className="text-zinc-700">PKR {x.price}</td>
                    <td>
                      <span
                        className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${
                          x.status === "approved"
                            ? "bg-emerald-50 text-emerald-900"
                            : x.status === "rejected"
                              ? "bg-red-50 text-red-800"
                              : "bg-amber-50 text-amber-900"
                        }`}
                      >
                        {x.status}
                      </span>
                    </td>
                    <td className="text-right">
                      <div className="inline-flex flex-wrap items-center justify-end gap-2">
                        <button
                          disabled={x.status !== "pending" || busyId === x.id}
                          onClick={() => setStatus(x.id, "approved")}
                          className="rounded-full border border-black/10 bg-white px-3 py-1.5 text-xs font-semibold hover:bg-black/5 disabled:opacity-50"
                        >
                          {busyId === x.id ? "…" : "Approve"}
                        </button>
                        <button
                          disabled={
                            (x.status !== "pending" && x.status !== "approved") ||
                            busyId === x.id
                          }
                          onClick={() => setStatus(x.id, "rejected")}
                          className="rounded-full border border-black/10 bg-white px-3 py-1.5 text-xs font-semibold hover:bg-black/5 disabled:opacity-50"
                        >
                          {busyId === x.id ? "…" : "Reject"}
                        </button>
                        <button
                          disabled={busyId === x.id}
                          onClick={() => deleteListing(x.id)}
                          className="rounded-full border border-red-200 bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-800 hover:bg-red-100 disabled:opacity-50"
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {filtered.length === 0 ? (
                  <tr>
                    <td className="py-6 text-sm text-zinc-600" colSpan={5}>
                      No listings.
                    </td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
