"use client";

import { useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";

export default function LoginForm() {
  const params = useSearchParams();
  const nextPath = useMemo(() => params.get("next") || "/admin/sellers", [params]);

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      if (!res.ok) {
        const j = (await res.json().catch(() => null)) as any;
        setError(j?.error ?? "Login failed");
        return;
      }
      window.location.href = nextPath;
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-zinc-50 px-5 py-16 text-zinc-950">
      <div className="mx-auto w-full max-w-md rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="h-10 w-10 rounded-xl bg-emerald-600" />
          <div>
            <div className="text-base font-semibold">Super Admin Login</div>
            <div className="text-xs text-zinc-600">AgriCare admin panel</div>
          </div>
        </div>

        <form onSubmit={onSubmit} className="mt-6 space-y-4">
          <div>
            <label className="text-xs font-semibold text-zinc-800">Email</label>
            <input
              className="mt-1 w-full rounded-2xl border border-black/10 bg-white px-4 py-3 text-sm outline-none focus:border-emerald-600"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@agricare.com"
              type="email"
              required
            />
          </div>
          <div>
            <label className="text-xs font-semibold text-zinc-800">
              Password
            </label>
            <input
              className="mt-1 w-full rounded-2xl border border-black/10 bg-white px-4 py-3 text-sm outline-none focus:border-emerald-600"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              type="password"
              required
            />
          </div>

          {error ? (
            <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
              {error}
            </div>
          ) : null}

          <button
            disabled={loading}
            type="submit"
            className="inline-flex h-11 w-full items-center justify-center rounded-full bg-emerald-600 px-5 text-sm font-semibold text-white hover:bg-emerald-700 disabled:opacity-60"
          >
            {loading ? "Signing in..." : "Sign in"}
          </button>

        
        </form>
      </div>
    </div>
  );
}

