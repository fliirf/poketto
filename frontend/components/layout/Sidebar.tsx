"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { BrandLogo } from "@/components/BrandLogo";
import { classNames } from "@/lib/format";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";

type SidebarBudget = {
  limit: number;
  used: number;
};

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
  const [budget, setBudget] = useState<SidebarBudget | null>(null);
  const [budgetLoading, setBudgetLoading] = useState(true);
  const [budgetError, setBudgetError] = useState(false);
  const limit = Number(budget?.limit ?? 0);
  const used = Number(budget?.used ?? 0);
  const progressRaw = limit > 0 ? (used / limit) * 100 : 0;
  const progress = Math.min(Math.max(progressRaw, 0), 100);
  const progressLabel = `${Math.round(progress)}%`;
  const hasBudget = limit > 0;
  const overLimit = hasBudget && used >= limit;
  const budgetStatus = budgetStatusText(progressRaw, hasBudget);
  const budgetTip = budgetTipText(progressRaw, hasBudget);
  const progressTone = overLimit ? "bg-red-500" : progress >= 80 ? "bg-amber-500" : "bg-[#ff8c42]";

  const loadSidebarBudget = useCallback(() => {
    if (!user) {
      setBudget(null);
      setBudgetLoading(false);
      return;
    }

    setBudgetLoading(true);
    setBudgetError(false);
    api
      .dashboard()
      .then((summary) => {
        setBudget({
          limit: Number(summary.monthly_budget || 0),
          used: Number(summary.monthly_expense || 0),
        });
      })
      .catch(() => {
        setBudget(null);
        setBudgetError(true);
      })
      .finally(() => setBudgetLoading(false));
  }, [user]);

  useEffect(() => {
    loadSidebarBudget();
  }, [loadSidebarBudget]);

  useEffect(() => {
    window.addEventListener("poketto:budget-refresh", loadSidebarBudget);
    return () => window.removeEventListener("poketto:budget-refresh", loadSidebarBudget);
  }, [loadSidebarBudget]);

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
          "fixed left-0 top-0 z-40 flex h-dvh min-h-dvh w-64 shrink-0 flex-col overflow-x-hidden overflow-y-auto rounded-r-[2.25rem] border-r border-[rgba(255,140,66,0.18)] bg-[#fff8f0] p-5 shadow-[8px_0_24px_rgba(120,70,20,0.06)] backdrop-blur-md transition lg:translate-x-0 lg:rounded-r-[2rem]",
          open ? "translate-x-0" : "-translate-x-full"
        )}
      >
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_28%_8%,rgba(255,140,66,0.20),transparent_12rem),radial-gradient(circle_at_80%_86%,rgba(255,184,108,0.20),transparent_14rem),linear-gradient(180deg,#fff8f0_0%,#ffeedf_100%)]"
        />
        <div aria-hidden="true" className="pointer-events-none absolute inset-y-6 right-0 w-px rounded-full bg-[linear-gradient(180deg,rgba(255,255,255,0.7),rgba(255,140,66,0.26),rgba(255,255,255,0.55))]" />

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
                  <p className="mt-1 text-sm font-bold leading-5 text-slate-600">
                    {budgetLoading ? "Memuat budget..." : budgetError ? "Budget belum bisa dimuat." : budgetStatus}
                  </p>
                </div>
                <span className={classNames(
                  "rounded-full px-2 py-1 text-xs font-black",
                  overLimit ? "bg-red-50 text-red-700" : progress >= 80 ? "bg-amber-50 text-amber-700" : "bg-poketto-50 text-poketto-700"
                )}>
                  {budgetLoading || budgetError ? "--" : hasBudget ? progressLabel : "0%"}
                </span>
              </div>
              <div className="mt-4 h-2 overflow-hidden rounded-full bg-orange-100/70">
                <div className={`h-full rounded-full transition-all ${progressTone}`} style={{ width: `${budgetLoading || budgetError ? 0 : progress}%` }} />
              </div>
              <p className="mt-3 text-xs font-semibold leading-5 text-slate-500">
                {budgetLoading ? "Mengecek ringkasan bulan ini..." : budgetError ? "Coba buka dashboard untuk memuat ulang." : budgetTip}
              </p>
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

function budgetStatusText(progress: number, hasBudget: boolean) {
  if (!hasBudget) return "Atur budget bulanan dulu.";
  if (progress >= 100) return "Budget bulan ini habis.";
  if (progress >= 80) return "Mendekati limit budget.";
  if (progress >= 50) return "Pengeluaran mulai naik.";
  return "Budget kamu masih aman.";
}

function budgetTipText(progress: number, hasBudget: boolean) {
  if (!hasBudget) return "Budget membantu kamu punya batas jelas.";
  if (progress >= 100) return "Evaluasi pengeluaran terbesar bulan ini.";
  if (progress >= 80) return "Kurangi transaksi impulsif hari ini.";
  if (progress >= 50) return "Cek kategori yang paling besar.";
  return "Pertahankan ritme pengeluaran.";
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
