"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { BrandLogo } from "@/components/BrandLogo";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { AppInput, Field } from "@/components/ui/AppInput";
import { ErrorState } from "@/components/ui/States";
import { useAuth } from "@/lib/auth";

export default function RegisterPage() {
  const { register } = useAuth();
  const [form, setForm] = useState({
    name: "",
    email: "",
    password: "",
    password_confirmation: ""
  });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError("");
    try {
      await register(form);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registrasi gagal.");
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
          <p className="mt-2 text-sm text-slate-500">Buat akun dan mulai catat keuangan.</p>
        </div>
        <AppCard className="border-white/80 bg-white/90 shadow-soft backdrop-blur-md">
          <form onSubmit={submit} className="grid gap-4">
            {error ? <ErrorState message={error} /> : null}
            <Field label="Nama">
              <AppInput value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} required />
            </Field>
            <Field label="Email">
              <AppInput type="email" value={form.email} onChange={(event) => setForm({ ...form, email: event.target.value })} required />
            </Field>
            <Field label="Password">
              <AppInput type="password" value={form.password} onChange={(event) => setForm({ ...form, password: event.target.value })} required />
            </Field>
            <Field label="Konfirmasi password">
              <AppInput
                type="password"
                value={form.password_confirmation}
                onChange={(event) => setForm({ ...form, password_confirmation: event.target.value })}
                required
              />
            </Field>
            <AppButton type="submit" disabled={loading} className="mt-2 w-full">
              {loading ? "Mendaftar..." : "Daftar"}
            </AppButton>
          </form>
          <p className="mt-5 text-center text-sm text-slate-500">
            Sudah punya akun?{" "}
            <Link href="/login" className="font-bold text-poketto-700">
              Masuk
            </Link>
          </p>
        </AppCard>
      </div>
    </main>
  );
}
