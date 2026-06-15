"use client";

import { classNames } from "@/lib/format";

type PasswordRule = {
  label: string;
  met: boolean;
};

type StrengthTone = "empty" | "weak" | "fair" | "strong" | "very-strong";

const toneStyles: Record<StrengthTone, { label: string; bar: string; icon: string; text: string; rule: string }> = {
  empty: {
    label: "Keamanan password",
    bar: "bg-orange-200/70",
    icon: "text-slate-400",
    text: "text-slate-600",
    rule: "text-slate-400",
  },
  weak: {
    label: "Password lemah",
    bar: "bg-[#fb7185]",
    icon: "text-rose-500",
    text: "text-red-700",
    rule: "text-red-600",
  },
  fair: {
    label: "Password cukup",
    bar: "bg-[#f59e0b]",
    icon: "text-amber-600",
    text: "text-amber-700",
    rule: "text-amber-700",
  },
  strong: {
    label: "Password kuat",
    bar: "bg-gradient-to-r from-[#ff8c42] to-[#22c55e]",
    icon: "text-poketto-700",
    text: "text-poketto-700",
    rule: "text-poketto-700",
  },
  "very-strong": {
    label: "Password sangat kuat",
    bar: "bg-[#16a34a]",
    icon: "text-emerald-700",
    text: "text-emerald-700",
    rule: "text-emerald-700",
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
    <div className="rounded-2xl border border-[rgba(255,140,66,0.14)] bg-[#fff8f0]/45 px-3 py-2">
      <div className="flex items-center justify-between gap-3">
        <div className="flex min-w-0 items-center gap-1.5">
          <span className={classNames("relative grid h-5 w-5 shrink-0 place-items-center", tone.icon)}>
            {strength.score >= 4 ? <ShieldCheckIcon /> : <LockIcon />}
            {showSparkle ? <span className="password-strength-sparkle absolute -right-0.5 -top-0.5 h-1.5 w-1.5 rounded-full bg-[#ffb86c]" /> : null}
          </span>
          <p className={classNames("truncate text-xs font-black", tone.text)}>{tone.label}</p>
        </div>
        <span className="shrink-0 text-[11px] font-black text-slate-500">{Math.round(strength.percent)}%</span>
      </div>

      <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-[#f4e7dc]">
        <div className={classNames("h-full rounded-full transition-all duration-300 ease-out", tone.bar)} style={{ width: `${strength.percent}%` }} />
      </div>

      <div className="mt-2 flex flex-wrap items-center gap-x-2.5 gap-y-1">
        {strength.rules.map((rule) => (
          <span key={rule.label} className={classNames("inline-flex min-w-0 items-center gap-1 text-[11px] font-bold leading-4", rule.met ? tone.rule : "text-slate-400")}>
            <span
              className={classNames(
                "grid h-3.5 w-3.5 shrink-0 place-items-center rounded-full",
                rule.met ? "text-emerald-700" : "border border-slate-300/70 text-slate-300"
              )}
            >
              {rule.met ? <CheckIcon /> : <span className="h-1.5 w-1.5 rounded-full bg-slate-300/80" />}
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
    <svg viewBox="0 0 24 24" aria-hidden="true" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2.2">
      <rect x="5" y="10" width="14" height="10" rx="3" />
      <path d="M8 10V7a4 4 0 0 1 8 0v3" />
    </svg>
  );
}

function ShieldCheckIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2.2">
      <path d="M12 3 19 6v5c0 4.5-2.8 8-7 10-4.2-2-7-5.5-7-10V6z" />
      <path d="m9 12 2 2 4-5" />
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg viewBox="0 0 16 16" aria-hidden="true" className="h-2.5 w-2.5" fill="none" stroke="currentColor" strokeWidth="2.4">
      <path d="m3.5 8 3 3 6-6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
