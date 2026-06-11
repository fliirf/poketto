"use client";

import { FormEvent, useEffect, useState } from "react";
import { AppLayout } from "@/components/layout/AppLayout";
import { PageHeader } from "@/components/layout/PageHeader";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { AppInput, Field } from "@/components/ui/AppInput";
import { AppSelect } from "@/components/ui/AppSelect";
import { ErrorState, LoadingState } from "@/components/ui/States";
import { useToast } from "@/components/ui/ToastProvider";
import { api } from "@/lib/api";
import { formatNumberInput, parseNumberInput, setStoredCurrency } from "@/lib/format";
import type { UserSettings } from "@/types/poketto";

const currencyOptions = ["IDR", "USD", "EUR", "SGD", "JPY"];

export default function SettingsPage() {
  const toast = useToast();
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [dailyBudgetInput, setDailyBudgetInput] = useState("");
  const [monthlyBudgetInput, setMonthlyBudgetInput] = useState("");
  const [thresholdInput, setThresholdInput] = useState("");

  useEffect(() => {
    api
      .userSettings()
      .then((data) => {
        setSettings(data.user_settings);
        setDailyBudgetInput(formatNumberInput(data.user_settings.daily_budget));
        setMonthlyBudgetInput(formatNumberInput(data.user_settings.monthly_budget));
        setThresholdInput(String(Math.round(Number(data.user_settings.budget_warning_threshold ?? 80))));
        setStoredCurrency(data.user_settings.currency);
      })
      .catch((err) => setError(err instanceof Error ? err.message : "Settings gagal dimuat."))
      .finally(() => setLoading(false));
  }, []);

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (!settings) return;
    if (saving) return;
    setSaving(true);
    setError("");
    try {
      const threshold = Math.max(1, Math.min(99, Number(thresholdInput || 80)));
      const data = await api.updateUserSettings({
        ...settings,
        budget_warning_threshold: threshold,
        currency: settings.currency.toUpperCase()
      });
      setSettings(data.user_settings);
      setDailyBudgetInput(formatNumberInput(data.user_settings.daily_budget));
      setMonthlyBudgetInput(formatNumberInput(data.user_settings.monthly_budget));
      setThresholdInput(String(Math.round(Number(data.user_settings.budget_warning_threshold ?? threshold))));
      setStoredCurrency(data.user_settings.currency);
      toast.success("Settings berhasil disimpan.");
    } catch (err) {
      const message = err instanceof Error ? err.message : "Settings gagal disimpan.";
      setError(message);
      toast.error(message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <AppLayout>
      <PageHeader title="Pengaturan" description="Atur budget, mata uang, notifikasi, dan preferensi lokasi." />
      {loading ? <LoadingState /> : null}
      {error ? <ErrorState message={error} /> : null}
      {settings ? (
        <AppCard className="mx-auto max-w-3xl">
          <form onSubmit={submit} className="grid gap-5">
            <div className="grid gap-4 md:grid-cols-2">
              <Field label="Daily budget">
                <AppInput
                  type="text"
                  inputMode="numeric"
                  value={dailyBudgetInput}
                  placeholder="Contoh: 1.000.000"
                  onChange={(event) => {
                    const formatted = formatNumberInput(event.target.value);
                    setDailyBudgetInput(formatted);
                    setSettings({ ...settings, daily_budget: parseNumberInput(formatted) });
                  }}
                />
              </Field>
              <Field label="Monthly budget">
                <AppInput
                  type="text"
                  inputMode="numeric"
                  value={monthlyBudgetInput}
                  placeholder="Contoh: 5.000.000"
                  onChange={(event) => {
                    const formatted = formatNumberInput(event.target.value);
                    setMonthlyBudgetInput(formatted);
                    setSettings({ ...settings, monthly_budget: parseNumberInput(formatted) });
                  }}
                />
              </Field>
              <Field label="Currency">
                <AppSelect
                  value={settings.currency}
                  onChange={(event) => setSettings({ ...settings, currency: event.target.value })}
                >
                  {currencyOptions.map((currency) => (
                    <option key={currency} value={currency}>
                      {currency}
                    </option>
                  ))}
                </AppSelect>
              </Field>
              <Field label="Budget warning threshold (%)">
                <div className="flex items-center rounded-2xl border border-slate-200 bg-white pr-4 focus-within:border-poketto-500 focus-within:ring-4 focus-within:ring-poketto-100">
                  <input
                    type="text"
                    inputMode="numeric"
                    className="min-h-11 w-full rounded-2xl bg-transparent px-4 text-sm font-medium outline-none"
                    value={thresholdInput}
                    onChange={(event) => {
                      const digits = event.target.value.replace(/\D/g, "").slice(0, 2);
                      setThresholdInput(digits);
                      setSettings({
                        ...settings,
                        budget_warning_threshold: digits ? Math.max(1, Math.min(99, Number(digits))) : undefined
                      });
                    }}
                    onBlur={() => {
                      const value = Math.max(1, Math.min(99, Number(thresholdInput || 80)));
                      setThresholdInput(String(value));
                      setSettings({ ...settings, budget_warning_threshold: value });
                    }}
                  />
                  <span className="text-sm font-black text-slate-400">%</span>
                </div>
              </Field>
            </div>
            <div className="grid gap-3 rounded-2xl bg-slate-50 p-4 sm:grid-cols-2">
              <label className="flex items-center justify-between gap-4 rounded-2xl bg-white px-4 py-3 text-sm font-bold text-slate-700">
                Notifikasi
                <input
                  type="checkbox"
                  className="h-5 w-5 accent-poketto-500"
                  checked={Boolean(settings.notification_enabled)}
                  onChange={(event) => setSettings({ ...settings, notification_enabled: event.target.checked })}
                />
              </label>
              <label className="flex items-center justify-between gap-4 rounded-2xl bg-white px-4 py-3 text-sm font-bold text-slate-700">
                Lokasi
                <input
                  type="checkbox"
                  className="h-5 w-5 accent-poketto-500"
                  checked={Boolean(settings.location_enabled)}
                  onChange={(event) => setSettings({ ...settings, location_enabled: event.target.checked })}
                />
              </label>
            </div>
            <div className="flex justify-end">
              <AppButton type="submit" disabled={saving}>
                {saving ? "Menyimpan..." : "Simpan settings"}
              </AppButton>
            </div>
          </form>
        </AppCard>
      ) : null}
    </AppLayout>
  );
}
