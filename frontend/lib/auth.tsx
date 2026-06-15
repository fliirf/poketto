"use client";

import { usePathname, useRouter } from "next/navigation";
import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { api, clearToken, getToken, setToken } from "@/lib/api";
import type { User } from "@/types/poketto";

type AuthContextValue = {
  user: User | null;
  token: string | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (payload: {
    name: string;
    email: string;
    password: string;
    password_confirmation: string;
  }) => Promise<void>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);
const publicRoutes = new Set(["/login", "/register"]);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [user, setUser] = useState<User | null>(null);
  const [token, setStoredToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const existing = getToken();
    setStoredToken(existing);
    if (!existing) {
      setLoading(false);
      return;
    }

    api
      .me()
      .then((data) => setUser(data.user))
      .catch(() => {
        clearToken();
        setStoredToken(null);
        setUser(null);
      })
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    if (loading) return;

    if (!token && !publicRoutes.has(pathname)) {
      router.replace("/login");
      return;
    }

    if (token && publicRoutes.has(pathname)) {
      router.replace("/dashboard");
    }
  }, [loading, pathname, router, token]);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      token,
      loading,
      async login(email, password) {
        const data = await api.login({ email, password });
        setToken(data.token);
        setStoredToken(data.token);
        setUser(data.user);
        router.replace("/dashboard");
      },
      async register(payload) {
        const data = await api.register(payload);
        setToken(data.token);
        setStoredToken(data.token);
        setUser(data.user);
        router.replace("/dashboard");
      },
      async logout() {
        try {
          await api.logout();
        } finally {
          clearToken();
          setStoredToken(null);
          setUser(null);
          router.replace("/login");
        }
      }
    }),
    [loading, router, token, user]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const value = useContext(AuthContext);
  if (!value) throw new Error("useAuth must be used inside AuthProvider");
  return value;
}
