"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { AuthLayout } from "@/components/layout/AuthLayout";
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
    <AuthLayout
      eyebrow="Mulai catat keuangan"
      title="Budget, transaksi, dan saldo dalam satu tempat."
      description="Buat akun dan mulai catat keuangan."
    >
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
    </AuthLayout>
  );
}
