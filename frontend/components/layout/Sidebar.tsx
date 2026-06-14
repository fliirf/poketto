"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { BrandLogo } from "@/components/BrandLogo";
import { classNames } from "@/lib/format";

const items = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/transactions", label: "Transaksi" },
  { href: "/categories", label: "Kategori" },
  { href: "/settings", label: "Pengaturan" }
];

export function Sidebar({ open, onClose }: { open: boolean; onClose: () => void }) {
  const pathname = usePathname();
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
          "fixed left-0 top-0 z-40 flex h-dvh min-h-dvh w-64 shrink-0 flex-col border-r border-white/70 bg-white/95 p-5 shadow-soft backdrop-blur transition lg:sticky lg:self-stretch lg:translate-x-0 lg:shadow-none",
          open ? "translate-x-0" : "-translate-x-full"
        )}
      >
        <Link href="/dashboard" className="mb-8" onClick={onClose}>
          <BrandLogo />
        </Link>

        <nav className="grid gap-2">
          {items.map((item) => {
            const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onClose}
                className={classNames(
                  "rounded-2xl px-4 py-3 text-sm font-bold transition",
                  active ? "bg-poketto-50 text-poketto-700 shadow-sm ring-1 ring-poketto-100" : "text-slate-500 hover:bg-slate-100 hover:text-slate-900"
                )}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>
      </aside>
    </>
  );
}
