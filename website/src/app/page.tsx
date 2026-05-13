import HomeNewsSection from "@/components/HomeNewsSection";

export default function Home() {
  return (
    <div
      id="home"
      className="min-h-screen bg-gradient-to-b from-white to-emerald-50 text-zinc-950"
    >
      <header className="sticky top-0 z-10 border-b border-black/5 bg-white/80 backdrop-blur">
        <div className="mx-auto flex w-full max-w-6xl items-center justify-between px-5 py-4">
          <a href="/" className="flex items-center gap-2">
            <div className="h-9 w-9 rounded-xl bg-emerald-600" />
            <div className="leading-tight">
              <div className="text-base font-semibold">AgriCare</div>
              <div className="text-xs text-zinc-600">
                AI-powered agricultural advisory
              </div>
            </div>
          </a>

          <nav className="hidden items-center gap-6 text-sm text-zinc-700 md:flex">
            <a className="hover:text-zinc-950" href="#home">
              Home
            </a>

            <a className="hover:text-zinc-950" href="#features">
              Features
            </a>

            <a className="hover:text-zinc-950" href="#about">
              About
            </a>

            <a className="hover:text-zinc-950" href="#news">
              News
            </a>

            <a className="hover:text-zinc-950" href="/admin">
              Admin Panel
            </a>
          </nav>

          <div className="flex items-center gap-3">
            <a
              className="rounded-full border border-black/10 bg-white px-4 py-2 text-sm font-medium hover:bg-black/5"
              href="/admin"
            >
              Admin Panel
            </a>
          </div>
        </div>
      </header>

      <main className="mx-auto w-full max-w-6xl px-5">
        {/* HERO */}
        <section className="grid gap-10 py-16 md:grid-cols-2 md:py-20">
          <div className="flex flex-col justify-center">
            <p className="mb-3 inline-flex w-fit items-center gap-2 rounded-full border border-emerald-600/20 bg-emerald-600/10 px-3 py-1 text-xs font-semibold text-emerald-800">
              Built for farmers and home gardeners
            </p>

            <h1 className="text-balance text-4xl font-semibold tracking-tight md:text-5xl">
              Smarter farming decisions with AI, real-time weather, and market
              insight
            </h1>

            <p className="mt-5 max-w-xl text-pretty text-lg leading-8 text-zinc-700">
              AgriCare analyzes soil conditions, weather patterns, and market
              trends to recommend crops, optimize harvest timing, and guide
              input usage—while connecting you to a marketplace and community
              support.
            </p>

            <div className="mt-7 flex flex-col gap-3 sm:flex-row">
              <a
                href="#features"
                className="inline-flex h-11 items-center justify-center rounded-full bg-emerald-600 px-5 text-sm font-semibold text-white hover:bg-emerald-700"
              >
                Explore features
              </a>

              <a
                href="/admin"
                className="inline-flex h-11 items-center justify-center rounded-full border border-black/10 bg-white px-5 text-sm font-semibold hover:bg-black/5"
              >
                Go to admin panel
              </a>
            </div>
          </div>

          <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="rounded-2xl bg-emerald-50 p-4">
                <div className="text-xs font-semibold text-emerald-900">
                  Crop selection
                </div>

                <div className="mt-2 text-sm text-zinc-700">
                  Best crops based on soil + weather + market trends.
                </div>
              </div>

              <div className="rounded-2xl bg-emerald-50 p-4">
                <div className="text-xs font-semibold text-emerald-900">
                  Inputs advice
                </div>

                <div className="mt-2 text-sm text-zinc-700">
                  Fertilizer and pesticide recommendations tailored to needs.
                </div>
              </div>

              <div className="rounded-2xl bg-emerald-50 p-4">
                <div className="text-xs font-semibold text-emerald-900">
                  Harvest timing
                </div>

                <div className="mt-2 text-sm text-zinc-700">
                  Optimize harvest windows using forecast + growth signals.
                </div>
              </div>

              <div className="rounded-2xl bg-emerald-50 p-4">
                <div className="text-xs font-semibold text-emerald-900">
                  Real-time dashboard
                </div>

                <div className="mt-2 text-sm text-zinc-700">
                  Weather, market prices, and agricultural news in one place.
                </div>
              </div>
            </div>

            <div className="mt-5 rounded-2xl border border-black/5 bg-white p-4">
              <div className="text-sm font-semibold">AI-powered chatbot</div>

              <div className="mt-1 text-sm text-zinc-700">
                24/7 answers to farming questions—fast, practical, and
                localized.
              </div>
            </div>
          </div>
        </section>

        {/* FEATURES */}
        <section id="features" className="py-14">
          <div className="flex flex-col gap-3">
            <h2 className="text-2xl font-semibold tracking-tight">
              Platform features
            </h2>

            <p className="max-w-3xl text-zinc-700">
              Everything you need—from recommendations and timing, to buying &
              selling, to learning from other farmers.
            </p>
          </div>

          <div className="mt-8 grid gap-4 md:grid-cols-2">
            {[
              {
                title: "AI-Based Crop Selection",
                desc: "Analyzes soil, weather, and market trends to suggest high-yield, high-profit crops.",
                img: "https://images.unsplash.com/photo-1464226184884-fa280b87c399?auto=format&fit=crop&w=1200&q=60",
              },
              {
                title: "Home Gardening Advisory",
                desc: "Tailored advice for growing fruits and vegetables at home based on local conditions.",
                img: "https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?auto=format&fit=crop&w=1200&q=60",
              },
              {
                title: "Fertilizer & Pesticide Recommendations",
                desc: "Specific input recommendations using AI analysis of soil and crop needs.",
                img: "https://images.unsplash.com/photo-1598514983175-5b9bcbf19a01?auto=format&fit=crop&w=1200&q=60",
              },
              {
                title: "Harvest Timing Optimization",
                desc: "Smart harvest guidance using forecasts and crop development signals.",
                img: "https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=60",
              },
              {
                title: "Agricultural Marketplace",
                desc: "Connect farmers with suppliers and buyers to purchase inputs and sell produce.",
                img: "https://images.unsplash.com/photo-1605000797499-95a51c5269ae?auto=format&fit=crop&w=1200&q=60",
              },
              {
                title: "Community Engagement",
                desc: "Group chat to exchange experiences, seek advice, and learn from peers.",
                img: "https://images.unsplash.com/photo-1523580846011-d3a5bc25702b?auto=format&fit=crop&w=1200&q=60",
              },
              {
                title: "News & Announcements",
                desc: "Timely updates on weather forecasts, market prices, and agricultural news.",
                img: "https://images.unsplash.com/photo-1560493676-04071c5f467b?auto=format&fit=crop&w=1200&q=60",
              },
              {
                title: "AI-Powered Chatbot",
                desc: "Quick answers to farming-related questions, available around the clock.",
                img: "https://images.unsplash.com/photo-1555255707-c07966088b7b?auto=format&fit=crop&w=1200&q=60",
              },
            ].map((f) => (
              <div
                key={f.title}
                className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm"
              >
                <div className="mb-4 overflow-hidden rounded-2xl border border-black/5 bg-zinc-50">
                  <img
                    src={f.img}
                    alt={f.title}
                    className="h-44 w-full object-cover"
                    loading="lazy"
                  />
                </div>

                <div className="text-sm font-semibold">{f.title}</div>

                <div className="mt-2 text-sm leading-7 text-zinc-700">
                  {f.desc}
                </div>
              </div>
            ))}
          </div>
        </section>

        <HomeNewsSection />

        {/* ABOUT */}
        <section id="about" className="py-14 pb-24">
          <div className="rounded-3xl border border-black/5 bg-white p-8 shadow-sm">
            <h2 className="text-2xl font-semibold tracking-tight">
              About the team
            </h2>

            <p className="mt-3 max-w-3xl text-zinc-700">
              AgriCare is built by a student team focused on practical,
              AI-driven tools for farmers and agricultural communities.
            </p>

            <div className="mt-6 grid gap-4 md:grid-cols-3">
              {[
                {
                  role: "Group Leader",
                  name: "Salaar Asim",
                  email: "salaarasim345@gmail.com",
                  image: "/team/salaar.jpeg",
                },
                {
                  role: "Member",
                  name: "Aqeel Saeed",
                  email: "aqeelsaeed138@gmail.com",
                  image: "/team/aqeel.jpeg",
                },
                {
                  role: "Member",
                  name: "Ali Ahmad Tahir",
                  email: "aliahmadtahir785@gmail.com",
                  image: "/team/ali.jpeg",
                },
              ].map((m) => (
                <div
                  key={m.email}
                  className="rounded-2xl border border-black/5 bg-zinc-50 p-5"
                >
                  <div className="flex items-center gap-4">
                    <img
                      src={m.image}
                      alt={m.name}
                      className="h-16 w-16 rounded-full object-cover border border-emerald-200"
                    />

                    <div>
                      <div className="text-xs font-semibold text-zinc-600">
                        {m.role}
                      </div>

                      <div className="text-base font-semibold">
                        {m.name}
                      </div>
                    </div>
                  </div>

                  <div className="mt-4 text-sm text-zinc-700">
                    {m.email}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>
      </main>

      {/* FOOTER */}
      <footer className="border-t border-black/5 bg-white">
        <div className="mx-auto flex w-full max-w-6xl items-center justify-between px-5 py-8 text-sm text-zinc-600">
          <div>© {new Date().getFullYear()} AgriCare</div>

          <div className="flex items-center gap-4">
            <a className="hover:text-zinc-900" href="#features">
              Features
            </a>

            <a className="hover:text-zinc-900" href="/admin">
              Admin
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}