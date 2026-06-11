"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { BrandLogo } from "@/components/BrandLogo";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { AppInput, Field } from "@/components/ui/AppInput";
import { ErrorState } from "@/components/ui/States";
import { useAuth } from "@/lib/auth";

export default function LoginPage() {
  const { login } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError("");
    try {
      await login(email, password);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login gagal.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="relative grid min-h-dvh place-items-center overflow-hidden bg-[linear-gradient(135deg,#fff7ed_0%,#f8fbff_42%,#eaf4ff_100%)] px-4 py-10">
      <div
        aria-hidden="true"
        className="absolute inset-0 bg-[linear-gradient(115deg,rgba(242,143,51,0.24)_0%,rgba(242,143,51,0.04)_34%,rgba(255,255,255,0)_62%),linear-gradient(245deg,rgba(14,165,233,0.18)_0%,rgba(14,165,233,0.03)_38%,rgba(255,255,255,0)_68%),repeating-linear-gradient(90deg,rgba(148,163,184,0.09)_0px,rgba(148,163,184,0.09)_1px,transparent_1px,transparent_84px)]"
      />
      <div aria-hidden="true" className="absolute inset-x-0 top-0 h-40 bg-gradient-to-b from-white/80 to-transparent" />
      <div className="relative z-10 w-full max-w-md">
        <div className="mb-8 rounded-[2rem] border border-white/70 bg-white/45 px-6 py-5 text-center shadow-soft backdrop-blur-md">
          <BrandLogo className="justify-center" />
          <p className="mt-2 text-sm text-slate-500">Masuk ke dashboard keuanganmu.</p>
        </div>
        <AppCard className="border-white/80 bg-white/90 shadow-soft backdrop-blur-md">
          <form onSubmit={submit} className="grid gap-4">
            {error ? <ErrorState message={error} /> : null}
            <Field label="Email">
              <AppInput type="email" value={email} onChange={(event) => setEmail(event.target.value)} required />
            </Field>
            <Field label="Password">
              <AppInput type="password" value={password} onChange={(event) => setPassword(event.target.value)} required />
            </Field>
            <AppButton type="submit" disabled={loading} className="mt-2 w-full">
              {loading ? "Masuk..." : "Masuk"}
            </AppButton>
          </form>
          <p className="mt-5 text-center text-sm text-slate-500">
            Belum punya akun?{" "}
            <Link href="/register" className="font-bold text-poketto-700">
              Daftar
            </Link>
          </p>
        </AppCard>
      </div>
    </main>
  );
}
