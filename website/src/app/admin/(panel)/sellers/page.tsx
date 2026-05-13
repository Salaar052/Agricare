"use client";

import { useEffect, useMemo, useState } from "react";

type Seller = {
  id: string;
  name: string;
  email: string;
  phone: string;
  status: "active" | "disabled";
  createdAt: string;
};

export default function SellersPage() {
  const [items, setItems] = useState<Seller[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [q, setQ] = useState("");
  const filtered = useMemo(() => {
    const s = q.trim().toLowerCase();
    if (!s) return items;
    return items.filter(
      (x) =>
        x.name.toLowerCase().includes(s) ||
        x.email.toLowerCase().includes(s) ||
        x.phone.toLowerCase().includes(s),
    );
  }, [items, q]);

  async function refresh() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/sellers", { cache: "no-store" });
      const j = (await res.json().catch(() => null)) as
        | Seller[]
        | { error?: string }
        | null;
      if (!res.ok) {
        setItems([]);
        setError((j as { error?: string } | null)?.error ?? "Failed to load sellers");
        return;
      }
      setItems(Array.isArray(j) ? j : []);
    } catch {
      setError("Failed to load sellers");
      setItems([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
  }, []);

  return (
    <div className="space-y-5">
      <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
        <h1 className="text-xl font-semibold tracking-tight">
          Sellers management
        </h1>
        <p className="mt-2 text-sm leading-7 text-zinc-700">
          Show registered sellers and manage their account status.
        </p>
      </div>

      <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
          <div className="text-sm font-semibold">Search</div>
          <input
            className="mt-4 w-full rounded-2xl border border-black/10 bg-white px-4 py-3 text-sm outline-none focus:border-emerald-600"
            placeholder="Search by name, email, phone..."
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
          <div className="mt-3 text-xs text-zinc-600">
            Showing <span className="font-semibold">{filtered.length}</span> of{" "}
            <span className="font-semibold">{items.length}</span>
          </div>
      </div>

      <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
        <div className="flex items-center justify-between">
          <div className="text-sm font-semibold">Registered sellers</div>
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
          <div className="mt-4 overflow-x-auto">
            <table className="w-full min-w-[760px] text-left text-sm">
              <thead className="text-xs text-zinc-600">
                <tr>
                  <th className="py-2">Name</th>
                  <th>Email</th>
                  <th>Phone</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody className="align-top">
                {filtered.map((s) => (
                  <tr key={s.id} className="border-t border-black/5">
                    <td className="py-3 font-medium">{s.name}</td>
                    <td className="text-zinc-700">{s.email}</td>
                    <td className="text-zinc-700">{s.phone}</td>
                    <td>
                      <span
                        className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${
                          s.status === "active"
                            ? "bg-emerald-50 text-emerald-900"
                            : "bg-zinc-100 text-zinc-700"
                        }`}
                      >
                        {s.status}
                      </span>
                    </td>
                  </tr>
                ))}
                {filtered.length === 0 ? (
                  <tr>
                    <td className="py-6 text-sm text-zinc-600" colSpan={4}>
                      No sellers found.
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

