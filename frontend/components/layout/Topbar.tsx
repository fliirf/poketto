"use client";

import { AppButton } from "@/components/ui/AppButton";
import { BrandLogo } from "@/components/BrandLogo";
import { useAuth } from "@/lib/auth";

export function Topbar({ onMenu }: { onMenu: () => void }) {
  const { user, logout } = useAuth();
  return (
    <header className="sticky top-0 z-20 -mx-4 mb-6 border-b border-white/70 bg-canvas/85 px-4 py-4 backdrop-blur md:mx-0 md:rounded-b-3xl md:border md:border-t-0">
      <div className="flex items-center justify-between gap-3">
        <button
          type="button"
          onClick={onMenu}
          className="grid h-11 w-11 place-items-center rounded-2xl border border-slate-200 bg-white text-slate-700 md:hidden"
          aria-label="Buka menu"
        >
          <span className="text-xl font-bold">=</span>
        </button>
        <div className="hidden sm:block">
          <p className="text-xs font-bold uppercase tracking-normal text-slate-400">Selamat datang</p>
          <p className="font-black text-slate-900">{user?.name ?? "Poketto user"}</p>
        </div>
        <BrandLogo compact className="sm:hidden" />
        <AppButton variant="secondary" onClick={logout}>
          Logout
        </AppButton>
      </div>
    </header>
  );
}
