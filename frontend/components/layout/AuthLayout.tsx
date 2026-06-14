import { BrandLogo } from "@/components/BrandLogo";
import { AuthMotionGraphic } from "@/components/layout/AuthMotionGraphic";
import type { ReactNode } from "react";

export function AuthLayout({
  children,
  eyebrow,
  title,
  description
}: {
  children: ReactNode;
  eyebrow: string;
  title: string;
  description: string;
}) {
  return (
    <main className="relative min-h-dvh overflow-x-hidden bg-[linear-gradient(135deg,#fff7ed_0%,#f8fbff_42%,#eaf4ff_100%)] px-4 py-8 sm:px-6 lg:px-8">
      <div
        aria-hidden="true"
        className="absolute inset-0 bg-[linear-gradient(115deg,rgba(242,143,51,0.24)_0%,rgba(242,143,51,0.04)_34%,rgba(255,255,255,0)_62%),linear-gradient(245deg,rgba(14,165,233,0.16)_0%,rgba(14,165,233,0.03)_38%,rgba(255,255,255,0)_68%),repeating-linear-gradient(90deg,rgba(148,163,184,0.08)_0px,rgba(148,163,184,0.08)_1px,transparent_1px,transparent_84px)]"
      />
      <div aria-hidden="true" className="absolute inset-x-0 top-0 h-40 bg-gradient-to-b from-white/80 to-transparent" />

      <div className="relative z-10 mx-auto grid min-h-[calc(100dvh-4rem)] w-full max-w-6xl items-center gap-8 lg:grid-cols-[minmax(0,1.05fr)_minmax(22rem,28rem)]">
        <section className="hidden min-w-0 lg:block">
          <BrandLogo />
          <div className="mt-10 max-w-xl">
            <p className="text-xs font-black uppercase tracking-normal text-poketto-700">{eyebrow}</p>
            <h1 className="mt-3 text-5xl font-black leading-tight text-slate-950">{title}</h1>
            <p className="mt-4 max-w-lg text-base font-semibold leading-7 text-slate-500">{description}</p>
          </div>
          <div className="mt-8">
            <AuthMotionGraphic />
          </div>
        </section>

        <section className="mx-auto grid w-full max-w-md gap-5">
          <div className="rounded-[2rem] border border-white/70 bg-white/55 px-6 py-5 text-center shadow-soft backdrop-blur-md lg:hidden">
            <BrandLogo className="justify-center" />
            <p className="mt-2 text-sm font-semibold text-slate-500">{description}</p>
          </div>
          {children}
        </section>
      </div>
    </main>
  );
}
