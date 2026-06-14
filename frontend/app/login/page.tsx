"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { AuthLayout } from "@/components/layout/AuthLayout";
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
    <AuthLayout
      eyebrow="Personal finance tracker"
      title="Kelola uang harian tanpa ribet."
      description="Masuk ke dashboard keuanganmu."
    >
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
    </AuthLayout>
  );
}
