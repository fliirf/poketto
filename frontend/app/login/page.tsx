"use client";

import { FormEvent, useState } from "react";
import { AuthLayout } from "@/components/layout/AuthLayout";
import { AuthTabs } from "@/components/layout/AuthTabs";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { AppInput, Field } from "@/components/ui/AppInput";
import { PasswordInput } from "@/components/ui/PasswordInput";
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
      <AppCard className="rounded-[2rem] border-white/80 bg-white/90 p-6 shadow-soft backdrop-blur-md sm:p-8">
        <AuthTabs active="login" />
        <form onSubmit={submit} className="mt-6 grid gap-4">
          {error ? <ErrorState message={error} /> : null}
          <Field label="Email">
            <AppInput type="email" value={email} onChange={(event) => setEmail(event.target.value)} className="min-h-12" required />
          </Field>
          <Field label="Password">
            <PasswordInput value={password} onChange={(event) => setPassword(event.target.value)} className="min-h-12" required />
          </Field>
          <AppButton type="submit" disabled={loading} className="mt-2 min-h-12 w-full">
            {loading ? "Masuk..." : "Masuk"}
          </AppButton>
        </form>
      </AppCard>
    </AuthLayout>
  );
}
