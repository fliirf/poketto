"use client";

import { useState } from "react";
import { Sidebar } from "@/components/layout/Sidebar";
import { Topbar } from "@/components/layout/Topbar";
import { LoadingState } from "@/components/ui/States";
import { useAuth } from "@/lib/auth";

export function AppLayout({ children }: { children: React.ReactNode }) {
  const [open, setOpen] = useState(false);
  const { loading, token } = useAuth();

  if (loading) {
    return (
      <main className="poketto-gradient-bg relative grid min-h-dvh place-items-center overflow-hidden p-4">
        <div aria-hidden="true" className="poketto-gradient-overlay absolute inset-0" />
        <div aria-hidden="true" className="absolute inset-x-0 top-0 h-40 bg-gradient-to-b from-white/80 to-transparent" />
        <div className="relative z-10 w-full max-w-md">
          <LoadingState label="Menyiapkan dashboard..." />
        </div>
      </main>
    );
  }

  if (!token) return null;

  return (
    <div className="poketto-workspace-bg relative min-h-dvh overflow-x-hidden lg:grid lg:grid-cols-[16rem_minmax(0,1fr)]">
      <div aria-hidden="true" className="poketto-workspace-overlay pointer-events-none fixed inset-0" />
      <div aria-hidden="true" className="pointer-events-none fixed inset-x-0 top-0 h-40 bg-gradient-to-b from-white/80 to-transparent" />
      <Sidebar open={open} onClose={() => setOpen(false)} />
      <main className="relative z-10 min-w-0 max-w-full px-3 pb-8 sm:px-4 lg:px-6 lg:pb-10 xl:px-8">
        <Topbar onMenu={() => setOpen(true)} />
        <div className="mx-auto w-full max-w-7xl min-w-0 animate-page-in">{children}</div>
      </main>
    </div>
  );
}
