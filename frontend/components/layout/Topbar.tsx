"use client";

import { AppButton } from "@/components/ui/AppButton";
import { BrandLogo } from "@/components/BrandLogo";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import type { BudgetNotification } from "@/types/poketto";
import { useEffect, useMemo, useRef, useState } from "react";

export function Topbar({ onMenu }: { onMenu: () => void }) {
  const { user, logout } = useAuth();
  const [open, setOpen] = useState(false);
  const [notifications, setNotifications] = useState<BudgetNotification[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const panelRef = useRef<HTMLDivElement>(null);
  const unreadCount = useMemo(() => notifications.filter((notification) => !notification.is_read).length, [notifications]);

  useEffect(() => {
    if (!user) return;

    setLoading(true);
    setError("");
    api
      .notifications()
      .then((data) => setNotifications(data.alerts ?? []))
      .catch((err) => setError(err instanceof Error ? err.message : "Notifikasi gagal dimuat."))
      .finally(() => setLoading(false));
  }, [user]);

  useEffect(() => {
    function closeOnOutsideClick(event: MouseEvent) {
      if (panelRef.current && !panelRef.current.contains(event.target as Node)) {
        setOpen(false);
      }
    }

    document.addEventListener("mousedown", closeOnOutsideClick);
    return () => document.removeEventListener("mousedown", closeOnOutsideClick);
  }, []);

  async function markAsRead(notification: BudgetNotification) {
    if (notification.is_read) return;

    setNotifications((current) => current.map((item) => item.id === notification.id ? { ...item, is_read: true } : item));
    if (!notification.id || notification.id <= 0) return;

    try {
      await api.markNotificationRead(notification.id);
    } catch {
      setNotifications((current) => current.map((item) => item.id === notification.id ? { ...item, is_read: false } : item));
    }
  }

  return (
    <header className="sticky top-0 z-20 -mx-4 mb-6 border-b border-white/70 bg-canvas/85 px-4 py-4 backdrop-blur lg:mx-0 lg:rounded-b-3xl lg:border lg:border-t-0">
      <div className="flex items-center justify-between gap-3">
        <button
          type="button"
          onClick={onMenu}
          className="grid h-11 w-11 place-items-center rounded-2xl border border-slate-200 bg-white text-slate-700 lg:hidden"
          aria-label="Buka menu"
        >
          <span className="text-xl font-bold">=</span>
        </button>
        <div className="hidden sm:block">
          <p className="text-xs font-bold uppercase tracking-normal text-slate-400">Selamat datang</p>
          <p className="font-black text-slate-900">{user?.name ?? "Poketto user"}</p>
        </div>
        <BrandLogo compact className="sm:hidden" />
        <div className="flex items-center gap-2">
          <div className="relative" ref={panelRef}>
            <button
              type="button"
              onClick={() => setOpen((current) => !current)}
              className="relative grid h-11 w-11 place-items-center rounded-2xl border border-slate-200 bg-white text-slate-700 shadow-sm transition hover:border-poketto-200 hover:bg-poketto-50 hover:text-poketto-700"
              aria-label="Buka notifikasi"
            >
              <svg viewBox="0 0 24 24" aria-hidden="true" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M15 17h5l-1.4-1.4A2 2 0 0 1 18 14.2V11a6 6 0 1 0-12 0v3.2c0 .5-.2 1-.6 1.4L4 17h5" />
                <path d="M9 17a3 3 0 0 0 6 0" />
              </svg>
              {unreadCount ? (
                <span className="absolute -right-1 -top-1 grid min-h-5 min-w-5 place-items-center rounded-full bg-red-500 px-1 text-[0.65rem] font-black text-white">
                  {unreadCount > 9 ? "9+" : unreadCount}
                </span>
              ) : null}
            </button>

            {open ? (
              <div className="absolute right-0 top-14 z-30 w-[min(22rem,calc(100vw-2rem))] overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-xl">
                <div className="flex items-center justify-between border-b border-slate-100 px-4 py-3">
                  <div>
                    <p className="font-black text-slate-900">Notifikasi</p>
                    <p className="text-xs font-semibold text-slate-400">{unreadCount} belum dibaca</p>
                  </div>
                  <button type="button" className="text-xs font-black text-slate-400 hover:text-slate-700" onClick={() => setOpen(false)}>
                    Tutup
                  </button>
                </div>
                <div className="max-h-80 overflow-y-auto p-2">
                  {loading ? (
                    <p className="rounded-xl bg-slate-50 px-3 py-4 text-sm font-semibold text-slate-500">Memuat notifikasi...</p>
                  ) : error ? (
                    <p className="rounded-xl bg-red-50 px-3 py-4 text-sm font-semibold text-red-600">{error}</p>
                  ) : notifications.length ? (
                    notifications.map((notification) => (
                      <button
                        key={notification.id}
                        type="button"
                        onClick={() => markAsRead(notification)}
                        className={`mb-2 block w-full rounded-xl px-3 py-3 text-left transition ${
                          notification.is_read ? "bg-slate-50 text-slate-500" : "bg-amber-50 text-amber-900 hover:bg-amber-100"
                        }`}
                      >
                        <span className="flex items-center justify-between gap-3">
                          <span className="text-sm font-black">{notification.title ?? "Budget perlu diperhatikan"}</span>
                          {!notification.is_read ? <span className="h-2 w-2 shrink-0 rounded-full bg-red-500" /> : null}
                        </span>
                        <span className="mt-1 block text-xs font-semibold leading-5">{notification.message}</span>
                      </button>
                    ))
                  ) : (
                    <p className="rounded-xl bg-slate-50 px-3 py-4 text-sm font-semibold text-slate-500">Belum ada notifikasi budget aktif.</p>
                  )}
                </div>
              </div>
            ) : null}
          </div>
          <AppButton variant="secondary" onClick={logout}>
            Logout
          </AppButton>
        </div>
      </div>
    </header>
  );
}
