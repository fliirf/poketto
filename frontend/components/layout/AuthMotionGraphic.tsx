import type { CSSProperties } from "react";

export function AuthMotionGraphic() {
  const bars = [46, 72, 54, 86, 66];

  return (
    <div className="auth-motion relative h-[28rem] w-full max-w-[36rem] overflow-hidden rounded-[2rem] border border-white/70 bg-white/45 p-6 shadow-soft backdrop-blur-md">
      <div aria-hidden="true" className="auth-blob auth-blob-one" />
      <div aria-hidden="true" className="auth-blob auth-blob-two" />
      <div aria-hidden="true" className="auth-ring left-10 top-12 h-24 w-24" />
      <div aria-hidden="true" className="auth-ring bottom-10 right-12 h-32 w-32" />

      <div className="auth-float absolute left-6 top-8 w-56 rounded-3xl border border-white/80 bg-white/80 p-4 shadow-xl backdrop-blur">
        <div className="flex items-center justify-between gap-3">
          <div>
            <p className="text-xs font-black uppercase tracking-normal text-slate-400">Saldo</p>
            <p className="mt-1 text-2xl font-black text-slate-950">Rp 4,5 jt</p>
          </div>
          <span className="grid h-11 w-11 place-items-center rounded-2xl bg-poketto-100 text-poketto-700 shadow-sm">
            <svg viewBox="0 0 24 24" aria-hidden="true" className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M4 7.5A2.5 2.5 0 0 1 6.5 5H19v14H6.5A2.5 2.5 0 0 1 4 16.5z" />
              <path d="M18 10h-4a3 3 0 0 0 0 6h4z" />
              <path d="M14 13h.01" />
            </svg>
          </span>
        </div>
        <div className="mt-4 h-2 overflow-hidden rounded-full bg-slate-100">
          <div className="auth-progress h-full rounded-full bg-poketto-500" />
        </div>
      </div>

      <div className="auth-float auth-float-delay absolute right-5 top-24 w-52 rounded-3xl border border-white/80 bg-white/80 p-4 shadow-xl backdrop-blur">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-xs font-black uppercase tracking-normal text-slate-400">Budget</p>
            <p className="mt-1 text-lg font-black text-emerald-700">Budget aman</p>
          </div>
          <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-black text-emerald-700">72%</span>
        </div>
        <div className="mt-5 flex h-24 items-end gap-2">
          {bars.map((height, index) => (
            <span
              key={height}
              className="auth-bar flex-1 rounded-t-xl bg-gradient-to-t from-poketto-500 to-amber-300"
              style={{ "--bar-height": `${height}%`, "--bar-delay": `${index * 90}ms` } as CSSProperties}
            />
          ))}
        </div>
      </div>

      <div className="auth-float auth-float-slow absolute bottom-10 left-12 w-64 rounded-3xl border border-white/80 bg-white/85 p-4 shadow-xl backdrop-blur">
        <div className="flex items-center justify-between gap-3">
          <div>
            <p className="text-xs font-black uppercase tracking-normal text-slate-400">Tren pengeluaran</p>
            <p className="mt-1 text-sm font-bold text-slate-700">Stabil minggu ini</p>
          </div>
          <span className="rounded-full bg-amber-50 px-3 py-1 text-xs font-black text-amber-700">-12%</span>
        </div>
        <svg viewBox="0 0 220 80" aria-hidden="true" className="mt-3 h-20 w-full overflow-visible">
          <path d="M4 62 C 38 18, 62 22, 88 44 S 142 72, 166 30 S 202 28, 216 18" className="auth-line" />
          <path d="M4 62 C 38 18, 62 22, 88 44 S 142 72, 166 30 S 202 28, 216 18 L216 78 L4 78 Z" fill="rgba(242,143,51,0.13)" />
          <circle cx="166" cy="30" r="5" className="auth-pulse-dot" />
        </svg>
      </div>

      <div className="auth-coin absolute bottom-28 right-20 grid h-16 w-16 place-items-center rounded-full bg-gradient-to-br from-amber-200 to-poketto-500 text-xl font-black text-white shadow-xl ring-4 ring-white/70">
        Rp
      </div>

      <div className="auth-alert absolute right-8 top-5 rounded-2xl border border-amber-100 bg-amber-50/95 px-4 py-3 text-sm font-black text-amber-800 shadow-lg">
        Budget tracked
      </div>
    </div>
  );
}
