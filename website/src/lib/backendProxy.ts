import { cookies } from "next/headers";

export const runtime = "nodejs";

export async function backendFetch(path: string, init?: RequestInit) {
  const base = (process.env.BACKEND_URL ?? "https://agricare-t3ou.onrender.com").replace(/\/$/, "");
  const url = `${base}${path.startsWith("/") ? path : `/${path}`}`;

  const jar = await cookies();
  const token = jar.get("agricare_admin_token")?.value;

  const headers = new Headers(init?.headers ?? undefined);
  if (token) headers.set("Authorization", `Bearer ${token}`);
  const body = init?.body;
  if (
    !headers.has("content-type") &&
    body &&
    !(typeof FormData !== "undefined" && body instanceof FormData)
  ) {
    headers.set("content-type", "application/json");
  }

  return fetch(url, {
    ...init,
    headers,
    cache: "no-store",
  });
}

