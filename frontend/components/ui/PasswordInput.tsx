"use client";

import { useState, type InputHTMLAttributes } from "react";
import { AppInput } from "@/components/ui/AppInput";

export function PasswordInput(props: Omit<InputHTMLAttributes<HTMLInputElement>, "type">) {
  const [visible, setVisible] = useState(false);

  return (
    <span className="relative block">
      <AppInput {...props} type={visible ? "text" : "password"} className={`w-full pr-12 ${props.className ?? ""}`} />
      <button
        type="button"
        aria-label={visible ? "Sembunyikan password" : "Tampilkan password"}
        onClick={() => setVisible((current) => !current)}
        className="absolute right-2 top-1/2 grid h-9 w-9 -translate-y-1/2 place-items-center rounded-xl text-slate-400 transition hover:bg-slate-50 hover:text-poketto-700 focus:outline-none focus:ring-4 focus:ring-poketto-100"
      >
        {visible ? <EyeOffIcon /> : <EyeIcon />}
      </button>
    </span>
  );
}

function EyeIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M2.5 12s3.5-6 9.5-6 9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  );
}

function EyeOffIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M3 3l18 18" />
      <path d="M10.6 10.6A3 3 0 0 0 13.4 13.4" />
      <path d="M9.9 5.2A9.6 9.6 0 0 1 12 5c6 0 9.5 7 9.5 7a16.9 16.9 0 0 1-3 3.8" />
      <path d="M6.5 6.9A16.8 16.8 0 0 0 2.5 12S6 19 12 19a9.7 9.7 0 0 0 4.1-.9" />
    </svg>
  );
}
