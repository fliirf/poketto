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
      <main className="grid min-h-dvh place-items-center p-4">
        <div className="w-full max-w-md">
          <LoadingState label="Menyiapkan dashboard..." />
        </div>
      </main>
    );
  }

  if (!token) return null;

  return (
    <div className="min-h-dvh overflow-x-hidden lg:grid lg:grid-cols-[16rem_minmax(0,1fr)]">
      <Sidebar open={open} onClose={() => setOpen(false)} />
      <main className="min-w-0 max-w-full px-3 pb-8 sm:px-4 lg:px-6 lg:pb-10 xl:px-8">
        <Topbar onMenu={() => setOpen(true)} />
        <div className="mx-auto w-full max-w-7xl min-w-0 animate-page-in">{children}</div>
      </main>
    </div>
  );
}
