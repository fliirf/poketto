"use client";

import { FormEvent, useState } from "react";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { AppInput, Field } from "@/components/ui/AppInput";
import { PasswordInput } from "@/components/ui/PasswordInput";
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

  return (
    <AppCard className="rounded-[2rem] border-white/80 bg-white/90 p-6 shadow-soft backdrop-blur-md sm:p-8">
      <AuthTabs active={activeMode} onChange={changeMode} />

      <div className="auth-panel-wrapper mt-6" data-direction={direction}>
        <div className={`auth-panel auth-panel-${panelState("login")}`} aria-hidden={activeMode !== "login"} inert={activeMode !== "login" ? true : undefined}>
          <form onSubmit={submitLogin} className="grid gap-4">
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
          </form>
        </div>

        <div className={`auth-panel auth-panel-${panelState("register")}`} aria-hidden={activeMode !== "register"} inert={activeMode !== "register" ? true : undefined}>
          <form onSubmit={submitRegister} className="grid gap-4">
            {registerError ? <ErrorState message={registerError} /> : null}
            <Field label="Nama">
              <AppInput
                value={registerForm.name}
                onChange={(event) => setRegisterForm({ ...registerForm, name: event.target.value })}
                className="min-h-12"
                required
              />
            </Field>
            <Field label="Email">
              <AppInput
                type="email"
                value={registerForm.email}
                onChange={(event) => setRegisterForm({ ...registerForm, email: event.target.value })}
                className="min-h-12"
                required
              />
            </Field>
            <Field label="Password">
              <PasswordInput
                value={registerForm.password}
                onChange={(event) => setRegisterForm({ ...registerForm, password: event.target.value })}
                className="min-h-12"
                required
              />
            </Field>
            <Field label="Konfirmasi password">
              <PasswordInput
                value={registerForm.password_confirmation}
                onChange={(event) => setRegisterForm({ ...registerForm, password_confirmation: event.target.value })}
                className="min-h-12"
                required
              />
            </Field>
            <AppButton type="submit" disabled={registerLoading} className="mt-2 min-h-12 w-full">
              {registerLoading ? "Mendaftar..." : "Daftar"}
            </AppButton>
          </form>
        </div>
      </div>
    </AppCard>
  );
}
