"use client";

import { createContext, useCallback, useContext, useMemo, useState } from "react";
import { classNames } from "@/lib/format";

type ToastTone = "success" | "error";
type Toast = {
  id: number;
  message: string;
  tone: ToastTone;
};

type ToastContextValue = {
  success: (message: string) => void;
  error: (message: string) => void;
};

const ToastContext = createContext<ToastContextValue | null>(null);

const toneClass: Record<ToastTone, string> = {
  success: "border-emerald-100 bg-emerald-600 text-white",
  error: "border-red-100 bg-red-600 text-white"
};

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const show = useCallback((message: string, tone: ToastTone) => {
    const id = Date.now() + Math.random();
    setToasts((current) => [...current, { id, message, tone }]);
    window.setTimeout(() => {
      setToasts((current) => current.filter((toast) => toast.id !== id));
    }, tone === "success" ? 3500 : 5500);
  }, []);

  const value = useMemo(
    () => ({
      success: (message: string) => show(message, "success"),
      error: (message: string) => show(message, "error")
    }),
    [show]
  );

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="fixed right-4 top-4 z-50 grid w-[min(24rem,calc(100vw-2rem))] gap-3" role="status" aria-live="polite">
        {toasts.map((toast) => (
          <div
            key={toast.id}
            className={classNames("rounded-2xl border px-4 py-3 text-sm font-bold shadow-lg", toneClass[toast.tone])}
          >
            {toast.message}
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error("useToast must be used within ToastProvider.");
  }
  return context;
}
