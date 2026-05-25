"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { AppInput, Field } from "@/components/ui/AppInput";
import { AppSelect } from "@/components/ui/AppSelect";
import { ErrorState } from "@/components/ui/States";
import { api } from "@/lib/api";
import type { Category, TransactionType } from "@/types/poketto";

export function CategoryForm({ category }: { category?: Category }) {
  const router = useRouter();
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    name: category?.name ?? "",
    type: category?.type ?? "expense",
    monthly_budget: Number(category?.monthly_budget ?? 0)
  });

  async function submit(event: FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError("");
    try {
      if (category) {
        await api.updateCategory(category.id, form);
      } else {
        await api.createCategory(form);
      }
      router.push("/categories");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Kategori gagal disimpan.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <AppCard>
      <form onSubmit={submit} className="grid gap-4">
        {error ? <ErrorState message={error} /> : null}
        <Field label="Nama kategori">
          <AppInput value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} required />
        </Field>
        <Field label="Tipe">
          <AppSelect value={form.type} onChange={(event) => setForm({ ...form, type: event.target.value as TransactionType })}>
            <option value="expense">Pengeluaran</option>
            <option value="income">Pemasukan</option>
          </AppSelect>
        </Field>
        <Field label="Budget bulanan">
          <AppInput
            type="number"
            min="0"
            step="1"
            value={form.monthly_budget}
            onChange={(event) => setForm({ ...form, monthly_budget: Number(event.target.value) })}
          />
        </Field>
        <div className="flex justify-end gap-2">
          <AppButton type="button" variant="secondary" onClick={() => router.back()}>
            Batal
          </AppButton>
          <AppButton type="submit" disabled={saving}>
            {saving ? "Menyimpan..." : "Simpan"}
          </AppButton>
        </div>
      </form>
    </AppCard>
  );
}
