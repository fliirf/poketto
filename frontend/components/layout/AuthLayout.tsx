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
    <main className="poketto-gradient-bg relative min-h-dvh overflow-x-hidden px-4 py-6 sm:px-6 lg:px-8">
      <div aria-hidden="true" className="poketto-gradient-overlay absolute inset-0" />
      <div aria-hidden="true" className="absolute inset-x-0 top-0 h-40 bg-gradient-to-b from-white/80 to-transparent" />

      <div className="relative z-10 mx-auto grid min-h-[calc(100dvh-3rem)] w-full max-w-[73.75rem] items-center gap-8 lg:grid-cols-[minmax(0,1.08fr)_minmax(24rem,27.5rem)] lg:gap-10 xl:gap-14">
        <section className="hidden min-w-0 lg:block">
          <BrandLogo />
          <div className="mt-8 max-w-[35rem]">
            <p className="text-xs font-black uppercase tracking-normal text-poketto-700">{eyebrow}</p>
            <h1 className="mt-3 text-[clamp(2.55rem,3.7vw,3.4rem)] font-black leading-[1.06] text-slate-950">{title}</h1>
            <p className="mt-4 max-w-lg text-base font-semibold leading-7 text-slate-500">{description}</p>
          </div>
          <div className="mt-6 max-w-[35.5rem]">
            <AuthMotionGraphic />
          </div>
        </section>

        <section className="mx-auto grid w-full max-w-[27.5rem] gap-5 lg:mx-0 lg:justify-self-end">
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
