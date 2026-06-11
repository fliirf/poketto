"use client";

import { FormEvent, useEffect, useState } from "react";
import { AppLayout } from "@/components/layout/AppLayout";
import { PageHeader } from "@/components/layout/PageHeader";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { AppInput, Field } from "@/components/ui/AppInput";
import { ErrorState, LoadingState } from "@/components/ui/States";
import { useToast } from "@/components/ui/ToastProvider";
import { api } from "@/lib/api";
import type { UserSettings } from "@/types/poketto";

export default function SettingsPage() {
  const toast = useToast();
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    api
      .userSettings()
      .then((data) => setSettings(data.user_settings))
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
      const data = await api.updateUserSettings({
        ...settings,
        currency: settings.currency.toUpperCase()
      });
      setSettings(data.user_settings);
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
                  type="number"
                  min="0"
                  step="1"
                  value={settings.daily_budget}
                  onChange={(event) => setSettings({ ...settings, daily_budget: Number(event.target.value) })}
                />
              </Field>
              <Field label="Monthly budget">
                <AppInput
                  type="number"
                  min="0"
                  step="1"
                  value={settings.monthly_budget}
                  onChange={(event) => setSettings({ ...settings, monthly_budget: Number(event.target.value) })}
                />
              </Field>
              <Field label="Currency">
                <AppInput value={settings.currency} maxLength={8} onChange={(event) => setSettings({ ...settings, currency: event.target.value })} />
              </Field>
              <Field label="Budget warning threshold">
                <AppInput
                  type="number"
                  min="1"
                  max="99"
                  step="1"
                  value={settings.budget_warning_threshold ?? 80}
                  onChange={(event) => setSettings({ ...settings, budget_warning_threshold: Number(event.target.value) })}
                />
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
