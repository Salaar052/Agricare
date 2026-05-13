import { NextResponse, type NextRequest } from "next/server";

const PROTECTED_PREFIXES = ["/admin"];
const PUBLIC_ADMIN_PATHS = ["/admin/login"];

export function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  const isProtected = PROTECTED_PREFIXES.some((p) => pathname.startsWith(p));
  if (!isProtected) return NextResponse.next();

  const isPublic = PUBLIC_ADMIN_PATHS.some((p) => pathname.startsWith(p));
  if (isPublic) return NextResponse.next();

  const token = req.cookies.get("agricare_admin_token")?.value;
  if (!token) {
    const url = req.nextUrl.clone();
    url.pathname = "/admin/login";
    url.searchParams.set("next", pathname);
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  // Match `/admin` and nested routes (`/admin/:path*` alone can miss `/admin` in some setups)
  matcher: ["/admin", "/admin/:path*"],
};

