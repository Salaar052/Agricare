import Link from "next/link";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-zinc-50 text-zinc-950">
      <header className="border-b border-black/5 bg-white">
        <div className="mx-auto flex w-full max-w-6xl items-center justify-between px-5 py-4">
          <div className="flex items-center gap-3">
            <div className="h-9 w-9 rounded-xl bg-emerald-600" />
            <div className="leading-tight">
              <div className="text-base font-semibold">AgriCare Admin</div>
              <div className="text-xs text-zinc-600">Super Admin panel</div>
            </div>
          </div>
          <form
            action={async () => {
              "use server";
              const jar = await cookies();
              jar.set("agricare_admin_token", "", {
                httpOnly: true,
                sameSite: "lax",
                secure: process.env.NODE_ENV === "production",
                path: "/",
                maxAge: 0,
              });
              jar.set("agricare_admin", "", {
                httpOnly: true,
                sameSite: "lax",
                secure: process.env.NODE_ENV === "production",
                path: "/",
                maxAge: 0,
              });
              redirect("/admin/login");
            }}
          >
            <button
              type="submit"
              className="rounded-full border border-black/10 bg-white px-4 py-2 text-sm font-semibold hover:bg-black/5"
            >
              Logout
            </button>
          </form>
        </div>
      </header>

      <div className="mx-auto grid w-full max-w-6xl gap-5 px-5 py-6 md:grid-cols-[240px_1fr]">
        <aside className="rounded-3xl border border-black/5 bg-white p-4 shadow-sm">
          <nav className="flex flex-col gap-1 text-sm">
            {[
              { href: "/admin/sellers", label: "Sellers" },
              { href: "/admin/news", label: "News & Content" },
              { href: "/admin/marketplace", label: "Marketplace Oversight" },
              { href: "/admin/community", label: "Community Moderation" },
            ].map((x) => (
              <Link
                key={x.href}
                href={x.href}
                className="rounded-2xl px-3 py-2 font-medium text-zinc-800 hover:bg-zinc-50 hover:text-zinc-950"
              >
                {x.label}
              </Link>
            ))}
          </nav>
          <div className="mt-4 rounded-2xl bg-emerald-50 p-3 text-xs text-emerald-900">
            You’re signed in as <span className="font-semibold">Super Admin</span>.
          </div>
        </aside>

        <section className="min-w-0">{children}</section>
      </div>
    </div>
  );
}

