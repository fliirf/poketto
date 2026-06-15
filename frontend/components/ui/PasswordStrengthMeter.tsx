"use client";

import { classNames } from "@/lib/format";

type PasswordRule = {
  label: string;
  met: boolean;
};

type StrengthTone = "empty" | "weak" | "fair" | "strong" | "very-strong";

const toneStyles: Record<StrengthTone, { label: string; message: string; bar: string; icon: string; text: string }> = {
  empty: {
    label: "Keamanan password",
    message: "Gunakan password yang aman untuk melindungi data keuanganmu.",
    bar: "bg-orange-200/70",
    icon: "bg-white text-slate-400",
    text: "text-slate-600",
  },
  weak: {
    label: "Password lemah",
    message: "Masih terlalu mudah ditebak.",
    bar: "bg-[#f87171]",
    icon: "bg-red-50 text-red-500",
    text: "text-red-700",
  },
  fair: {
    label: "Password cukup",
    message: "Sudah lebih baik, tambahkan simbol agar lebih aman.",
    bar: "bg-[#f59e0b]",
    icon: "bg-amber-50 text-amber-600",
    text: "text-amber-700",
  },
  strong: {
    label: "Password kuat",
    message: "Password sudah cukup aman.",
    bar: "bg-gradient-to-r from-[#ff8c42] to-[#22c55e]",
    icon: "bg-orange-50 text-poketto-700",
    text: "text-poketto-700",
  },
  "very-strong": {
    label: "Password sangat kuat",
    message: "Mantap, data keuanganmu lebih terlindungi.",
    bar: "bg-[#16a34a]",
    icon: "bg-emerald-50 text-emerald-700",
    text: "text-emerald-700",
  },
};

export function getPasswordStrength(password: string) {
  const rules: PasswordRule[] = [
    { label: "8+ karakter", met: password.length >= 8 },
    { label: "Huruf besar", met: /[A-Z]/.test(password) },
    { label: "Huruf kecil", met: /[a-z]/.test(password) },
    { label: "Angka", met: /\d/.test(password) },
    { label: "Simbol", met: /[^A-Za-z0-9]/.test(password) },
  ];
  const score = password ? rules.filter((rule) => rule.met).length : 0;
  const tone: StrengthTone = !password ? "empty" : score <= 1 ? "weak" : score <= 3 ? "fair" : score === 4 ? "strong" : "very-strong";

  return {
    rules,
    score,
    tone,
    percent: password ? (score / rules.length) * 100 : 0,
  };
}

export function PasswordStrengthMeter({ password }: { password: string }) {
  const strength = getPasswordStrength(password);
  const tone = toneStyles[strength.tone];
  const showSparkle = strength.tone === "strong" || strength.tone === "very-strong";

  return (
    <div className="relative overflow-hidden rounded-2xl border border-orange-100/80 bg-[#fff8f0]/80 p-3 shadow-[0_12px_26px_rgba(120,70,20,0.06)]">
      <div aria-hidden="true" className="pointer-events-none absolute -right-8 -top-10 h-20 w-20 rounded-full bg-orange-200/20 blur-xl" />
      <div className="relative flex items-center justify-between gap-3">
        <div className="flex min-w-0 items-center gap-2">
          <span className={classNames("relative grid h-8 w-8 shrink-0 place-items-center rounded-xl shadow-sm", tone.icon)}>
            {strength.score >= 4 ? <ShieldCheckIcon /> : <LockIcon />}
            {showSparkle ? <span className="password-strength-sparkle absolute -right-1 -top-1 h-2 w-2 rounded-full bg-[#ffb86c]" /> : null}
          </span>
          <div className="min-w-0">
            <p className={classNames("truncate text-xs font-black", tone.text)}>{tone.label}</p>
            <p className="truncate text-[11px] font-semibold text-slate-500">{tone.message}</p>
          </div>
        </div>
        <span className="shrink-0 rounded-full bg-white/80 px-2 py-1 text-[11px] font-black text-slate-500 shadow-sm">{Math.round(strength.percent)}%</span>
      </div>

      <div className="relative mt-3 h-2 overflow-hidden rounded-full bg-[#ffe7cf]">
        <div className={classNames("h-full rounded-full transition-all duration-300 ease-out", tone.bar)} style={{ width: `${strength.percent}%` }} />
      </div>

      <div className="mt-3 grid grid-cols-2 gap-x-3 gap-y-1.5">
        {strength.rules.map((rule) => (
          <span key={rule.label} className={classNames("flex min-w-0 items-center gap-1.5 text-[11px] font-bold", rule.met ? "text-emerald-700" : "text-slate-400")}>
            <span
              className={classNames(
                "grid h-4 w-4 shrink-0 place-items-center rounded-full text-[9px]",
                rule.met ? "bg-emerald-50 text-emerald-700" : "border border-slate-200 bg-white/70 text-slate-300"
              )}
            >
              {rule.met ? <CheckIcon /> : null}
            </span>
            <span className="truncate">{rule.label}</span>
          </span>
        ))}
      </div>
    </div>
  );
}

function LockIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.2">
      <rect x="5" y="10" width="14" height="10" rx="3" />
      <path d="M8 10V7a4 4 0 0 1 8 0v3" />
    </svg>
  );
}

function ShieldCheckIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2.2">
      <path d="M12 3 19 6v5c0 4.5-2.8 8-7 10-4.2-2-7-5.5-7-10V6z" />
      <path d="m9 12 2 2 4-5" />
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg viewBox="0 0 16 16" aria-hidden="true" className="h-3 w-3" fill="none" stroke="currentColor" strokeWidth="2.4">
      <path d="m3.5 8 3 3 6-6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
