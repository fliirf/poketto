"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { BrandLogo } from "@/components/BrandLogo";
import { classNames } from "@/lib/format";
import { useAuth } from "@/lib/auth";

const items = [
  { href: "/dashboard", label: "Dashboard", icon: DashboardIcon },
  { href: "/transactions", label: "Transaksi", icon: ReceiptIcon },
  { href: "/categories", label: "Kategori", icon: TagIcon },
  { href: "/settings", label: "Pengaturan", icon: SettingsIcon }
];

export function Sidebar({ open, onClose }: { open: boolean; onClose: () => void }) {
  const pathname = usePathname();
  const { user } = useAuth();
  const userInitial = (user?.name?.trim()?.charAt(0) || "U").toUpperCase();

  return (
    <>
      <div
        className={classNames(
          "fixed inset-0 z-30 bg-slate-950/30 transition lg:hidden",
          open ? "opacity-100" : "pointer-events-none opacity-0"
        )}
        onClick={onClose}
      />
      <aside
        className={classNames(
          "fixed left-0 top-0 z-40 flex h-dvh min-h-dvh w-64 shrink-0 flex-col overflow-hidden border-r border-orange-100/70 bg-[#fff8f0] p-5 shadow-soft backdrop-blur-md transition lg:sticky lg:self-stretch lg:translate-x-0 lg:shadow-none",
          open ? "translate-x-0" : "-translate-x-full"
        )}
      >
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_28%_8%,rgba(255,140,66,0.20),transparent_12rem),radial-gradient(circle_at_80%_86%,rgba(255,184,108,0.20),transparent_14rem),linear-gradient(180deg,#fff8f0_0%,#ffeedf_100%)]"
        />
        <div aria-hidden="true" className="pointer-events-none absolute inset-y-0 right-0 w-px bg-white/70" />

        <div className="relative z-10 flex min-h-0 flex-1 flex-col">
          <Link href="/dashboard" className="mb-7 rounded-[1.4rem] p-1 transition hover:bg-white/35 focus:outline-none focus:ring-4 focus:ring-poketto-100" onClick={onClose}>
            <BrandLogo />
          </Link>

          <nav className="grid gap-2">
            {items.map((item) => {
              const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
              const Icon = item.icon;

              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={onClose}
                  aria-current={active ? "page" : undefined}
                  className={classNames(
                    "group flex min-h-12 items-center gap-3 rounded-2xl px-3 py-2 text-sm font-black transition duration-200 focus:outline-none focus:ring-4 focus:ring-poketto-100",
                    active
                      ? "bg-[#ff8c42] text-white shadow-[0_14px_28px_rgba(255,140,66,0.28)]"
                      : "text-slate-600 hover:translate-x-0.5 hover:bg-white/60 hover:text-poketto-700"
                  )}
                >
                  <span
                    className={classNames(
                      "grid h-9 w-9 shrink-0 place-items-center rounded-xl transition",
                      active ? "bg-white/20 text-white" : "bg-white/60 text-poketto-600 group-hover:bg-poketto-50 group-hover:text-poketto-700"
                    )}
                  >
                    <Icon />
                  </span>
                  <span>{item.label}</span>
                </Link>
              );
            })}
          </nav>

          <div className="mt-auto grid gap-3 pt-6">
            <div className="rounded-3xl border border-white/70 bg-white/55 p-4 shadow-sm backdrop-blur">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <p className="text-xs font-black uppercase tracking-normal text-poketto-700">Budget bulan ini</p>
                  <p className="mt-1 text-sm font-bold leading-5 text-slate-600">Pantau budget kamu tetap rapi.</p>
                </div>
                <span className="rounded-full bg-poketto-50 px-2 py-1 text-xs font-black text-poketto-700">72%</span>
              </div>
              <div className="mt-4 h-2 overflow-hidden rounded-full bg-orange-100/70">
                <div className="h-full w-[72%] rounded-full bg-[#ff8c42]" />
              </div>
            </div>

            <div className="flex items-center gap-3 rounded-3xl border border-white/70 bg-white/55 p-3 shadow-sm backdrop-blur">
              <span className="grid h-11 w-11 shrink-0 place-items-center rounded-2xl bg-[#ff8c42] text-sm font-black text-white shadow-[0_10px_20px_rgba(255,140,66,0.22)]">
                {userInitial}
              </span>
              <span className="min-w-0">
                <span className="block truncate text-sm font-black text-slate-800">{user?.name ?? "User"}</span>
                <span className="block truncate text-xs font-semibold text-slate-500">{user?.email ?? "Poketto account"}</span>
              </span>
            </div>
          </div>
        </div>
      </aside>
    </>
  );
}

function DashboardIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M4 5a1 1 0 0 1 1-1h5v7H4z" />
      <path d="M14 4h5a1 1 0 0 1 1 1v4h-6z" />
      <path d="M4 15h6v5H5a1 1 0 0 1-1-1z" />
      <path d="M14 13h6v6a1 1 0 0 1-1 1h-5z" />
    </svg>
  );
}

function ReceiptIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M6 3h12v18l-2-1.2-2 1.2-2-1.2-2 1.2-2-1.2L6 21z" />
      <path d="M9 8h6" />
      <path d="M9 12h6" />
      <path d="M9 16h3" />
    </svg>
  );
}

function TagIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M20 13.5 13.5 20a2 2 0 0 1-2.8 0L4 13.3V4h9.3L20 10.7a2 2 0 0 1 0 2.8z" />
      <path d="M8 8h.01" />
    </svg>
  );
}

function SettingsIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M12 15.5A3.5 3.5 0 1 0 12 8a3.5 3.5 0 0 0 0 7.5z" />
      <path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1-2 3.4-.2-.1a1.8 1.8 0 0 0-2 .1 1.7 1.7 0 0 0-.8 1.6v.2H9.2V22a1.7 1.7 0 0 0-.8-1.6 1.8 1.8 0 0 0-2-.1l-.2.1-2-3.4.1-.1a1.7 1.7 0 0 0 .3-1.9 1.7 1.7 0 0 0-1.4-1H3v-4h.2a1.7 1.7 0 0 0 1.4-1 1.7 1.7 0 0 0-.3-1.9l-.1-.1 2-3.4.2.1a1.8 1.8 0 0 0 2-.1A1.7 1.7 0 0 0 9.2 2v-.2h5.6V2a1.7 1.7 0 0 0 .8 1.6 1.8 1.8 0 0 0 2 .1l.2-.1 2 3.4-.1.1a1.7 1.7 0 0 0-.3 1.9 1.7 1.7 0 0 0 1.4 1h.2v4h-.2a1.7 1.7 0 0 0-1.4 1z" />
    </svg>
  );
}
