"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { AppInput, Field } from "@/components/ui/AppInput";
import { AppSelect } from "@/components/ui/AppSelect";
import { ErrorState } from "@/components/ui/States";
import { useToast } from "@/components/ui/ToastProvider";
import { api } from "@/lib/api";
import type { Category, TransactionType } from "@/types/poketto";

export function CategoryForm({ category, onSaved }: { category?: Category; onSaved?: () => void | Promise<void> }) {
  const router = useRouter();
  const toast = useToast();
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    name: category?.name ?? "",
    type: category?.type ?? "expense",
    monthly_budget: Number(category?.monthly_budget ?? 0)
  });

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (saving) return;
    if (!form.name.trim()) {
      const message = "Nama kategori wajib diisi.";
      setError(message);
      toast.error(message);
      return;
    }

    setSaving(true);
    setError("");
    try {
      if (category) {
        await api.updateCategory(category.id, form);
        toast.success("Kategori berhasil diperbarui.");
        router.push("/categories");
      } else {
        await api.createCategory(form);
        toast.success("Kategori berhasil ditambahkan.");
        await onSaved?.();
        setForm({ name: "", type: form.type, monthly_budget: 0 });
      }
      router.refresh();
    } catch (err) {
      const message = err instanceof Error ? err.message : "Kategori gagal disimpan.";
      setError(message);
      toast.error(message);
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
