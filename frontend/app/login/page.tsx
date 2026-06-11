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
    <main className="grid min-h-dvh place-items-center px-4 py-10">
      <div className="w-full max-w-md">
        <div className="mb-8 text-center">
          <BrandLogo className="justify-center" />
          <p className="mt-2 text-sm text-slate-500">Masuk ke dashboard keuanganmu.</p>
        </div>
        <AppCard>
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
