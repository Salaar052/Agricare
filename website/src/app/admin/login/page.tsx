import { Suspense } from "react";
import LoginForm from "./ui";

export default function AdminLoginPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen bg-zinc-50 px-5 py-16 text-zinc-950">
          <div className="mx-auto w-full max-w-md rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
            <div className="text-sm text-zinc-600">Loading...</div>
          </div>
        </div>
      }
    >
      <LoginForm />
    </Suspense>
  );
}

