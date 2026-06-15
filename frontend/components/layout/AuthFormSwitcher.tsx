"use client";

import { FormEvent, useState } from "react";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { AppInput, Field } from "@/components/ui/AppInput";
import { PasswordInput } from "@/components/ui/PasswordInput";
import { PasswordStrengthMeter } from "@/components/ui/PasswordStrengthMeter";
import { ErrorState } from "@/components/ui/States";
import { AuthTabs, type AuthMode } from "@/components/layout/AuthTabs";
import { useAuth } from "@/lib/auth";

const modeOrder: Record<AuthMode, number> = {
  login: 0,
  register: 1,
};

export function AuthFormSwitcher({ initialMode }: { initialMode: AuthMode }) {
  const { login, register } = useAuth();
  const [activeMode, setActiveMode] = useState<AuthMode>(initialMode);
  const [direction, setDirection] = useState<"forward" | "backward">("forward");
  const [loginForm, setLoginForm] = useState({ email: "", password: "" });
  const [registerForm, setRegisterForm] = useState({
    name: "",
    email: "",
    password: "",
    password_confirmation: "",
  });
  const [loginError, setLoginError] = useState("");
  const [registerError, setRegisterError] = useState("");
  const [loginLoading, setLoginLoading] = useState(false);
  const [registerLoading, setRegisterLoading] = useState(false);

  function changeMode(nextMode: AuthMode) {
    if (nextMode === activeMode) return;

    setDirection(modeOrder[nextMode] > modeOrder[activeMode] ? "forward" : "backward");
    setActiveMode(nextMode);

    if (typeof window !== "undefined") {
      window.history.pushState(null, "", nextMode === "login" ? "/login" : "/register");
    }
  }

  function panelState(mode: AuthMode) {
    if (activeMode === mode) return "visible";

    if (activeMode === "register" && mode === "login") {
      return "hidden-left";
    }

    return "hidden-right";
  }

  async function submitLogin(event: FormEvent) {
    event.preventDefault();
    setLoginLoading(true);
    setLoginError("");
    try {
      await login(loginForm.email, loginForm.password);
    } catch (err) {
      setLoginError(err instanceof Error ? err.message : "Login gagal.");
    } finally {
      setLoginLoading(false);
    }
  }

  async function submitRegister(event: FormEvent) {
    event.preventDefault();
    setRegisterLoading(true);
    setRegisterError("");
    try {
      await register(registerForm);
    } catch (err) {
      setRegisterError(err instanceof Error ? err.message : "Registrasi gagal.");
    } finally {
      setRegisterLoading(false);
    }
  }

  const confirmPasswordState = registerForm.password_confirmation
    ? registerForm.password === registerForm.password_confirmation
      ? "match"
      : "mismatch"
    : "empty";

  return (
    <AppCard className="rounded-[2rem] border-white/90 bg-white/[0.92] p-6 shadow-[0_22px_58px_rgba(23,32,51,0.10)] backdrop-blur-md sm:p-8">
      <AuthTabs active={activeMode} onChange={changeMode} />

      <div className="auth-panel-wrapper mt-6" data-active-mode={activeMode} data-direction={direction}>
        <div className={`auth-panel auth-panel-${panelState("login")}`} aria-hidden={activeMode !== "login"} inert={activeMode !== "login" ? true : undefined}>
          <form onSubmit={submitLogin} className="grid gap-4">
            <div className="mb-1">
              <h2 className="text-2xl font-black text-slate-950">Selamat datang kembali</h2>
              <p className="mt-1 text-sm font-semibold leading-6 text-slate-500">Masuk untuk lanjut mengelola keuanganmu.</p>
            </div>
            {loginError ? <ErrorState message={loginError} /> : null}
            <Field label="Email">
              <AppInput
                type="email"
                value={loginForm.email}
                onChange={(event) => setLoginForm({ ...loginForm, email: event.target.value })}
                className="min-h-12"
                required
              />
            </Field>
            <Field label="Password">
              <PasswordInput
                value={loginForm.password}
                onChange={(event) => setLoginForm({ ...loginForm, password: event.target.value })}
                className="min-h-12"
                required
              />
            </Field>
            <AppButton type="submit" disabled={loginLoading} className="mt-2 min-h-12 w-full">
              {loginLoading ? "Masuk..." : "Masuk"}
            </AppButton>
            <p className="text-center text-xs font-semibold text-slate-400">Data keuanganmu aman bersama Poketto.</p>
          </form>
        </div>

        <div className={`auth-panel auth-panel-${panelState("register")}`} aria-hidden={activeMode !== "register"} inert={activeMode !== "register" ? true : undefined}>
          <form onSubmit={submitRegister} className="grid gap-1.5">
            <div>
              <h2 className="text-[1.35rem] font-black leading-7 text-slate-950">Buat akun Poketto</h2>
              <p className="mt-0.5 text-xs font-semibold leading-5 text-slate-500">Mulai catat pemasukan dan pengeluaranmu.</p>
            </div>
            {registerError ? <ErrorState message={registerError} /> : null}
            <Field label="Nama" className="gap-1">
              <AppInput
                value={registerForm.name}
                onChange={(event) => setRegisterForm({ ...registerForm, name: event.target.value })}
                className="h-10 min-h-10"
                required
              />
            </Field>
            <Field label="Email" className="gap-1">
              <AppInput
                type="email"
                value={registerForm.email}
                onChange={(event) => setRegisterForm({ ...registerForm, email: event.target.value })}
                className="h-10 min-h-10"
                required
              />
            </Field>
            <Field label="Password" className="gap-1">
              <PasswordInput
                value={registerForm.password}
                onChange={(event) => setRegisterForm({ ...registerForm, password: event.target.value })}
                className="h-10 min-h-10"
                required
              />
            </Field>
            <PasswordStrengthMeter password={registerForm.password} />
            <Field label="Konfirmasi password" className="gap-1">
              <PasswordInput
                value={registerForm.password_confirmation}
                onChange={(event) => setRegisterForm({ ...registerForm, password_confirmation: event.target.value })}
                className="h-10 min-h-10"
                required
              />
              {confirmPasswordState !== "empty" ? (
                <span className={`text-[11px] font-bold ${confirmPasswordState === "match" ? "text-emerald-700" : "text-red-600"}`}>
                  {confirmPasswordState === "match" ? "Password cocok." : "Konfirmasi password belum sama."}
                </span>
              ) : null}
            </Field>
            <AppButton type="submit" disabled={registerLoading} className="min-h-10 w-full">
              {registerLoading ? "Mendaftar..." : "Daftar"}
            </AppButton>
            <p className="text-center text-xs font-semibold text-slate-400">Mulai kelola budget harian dengan lebih rapi.</p>
          </form>
        </div>
      </div>
    </AppCard>
  );
}
