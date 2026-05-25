"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { AppInput, AppTextarea, Field } from "@/components/ui/AppInput";
import { AppSelect } from "@/components/ui/AppSelect";
import { ErrorState } from "@/components/ui/States";
import { api, type TransactionPayload } from "@/lib/api";
import { toDateTimeLocal } from "@/lib/format";
import type { Category, Transaction, TransactionType } from "@/types/poketto";

export function TransactionForm({
  categories,
  transaction
}: {
  categories: Category[];
  transaction?: Transaction;
}) {
  const router = useRouter();
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState<TransactionPayload>({
    type: transaction?.type ?? "expense",
    category_id: transaction?.category_id ?? null,
    amount: transaction?.amount ?? 0,
    transaction_date: toDateTimeLocal(transaction?.transaction_date ?? transaction?.date),
    description: transaction?.description ?? ""
  });

  async function submit(event: FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError("");
    try {
      if (transaction) {
        await api.updateTransaction(transaction.id, form);
      } else {
        await api.createTransaction(form);
      }
      router.push("/transactions");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Transaksi gagal disimpan.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <AppCard className="mx-auto max-w-2xl">
      <form onSubmit={submit} className="grid gap-4">
        {error ? <ErrorState message={error} /> : null}
        <Field label="Tipe">
          <AppSelect value={form.type} onChange={(event) => setForm({ ...form, type: event.target.value as TransactionType })}>
            <option value="expense">Pengeluaran</option>
            <option value="income">Pemasukan</option>
          </AppSelect>
        </Field>
        <Field label="Nominal">
          <AppInput
            type="number"
            min="0.01"
            step="0.01"
            value={form.amount || ""}
            onChange={(event) => setForm({ ...form, amount: Number(event.target.value) })}
            required
          />
        </Field>
        <Field label="Kategori">
          <AppSelect
            value={form.category_id ?? ""}
            onChange={(event) => setForm({ ...form, category_id: event.target.value ? Number(event.target.value) : null })}
            required={form.type === "expense"}
          >
            <option value="">Pilih kategori</option>
            {categories.map((category) => (
              <option key={category.id} value={category.id}>
                {category.name} ({category.type === "income" ? "Pemasukan" : "Pengeluaran"})
              </option>
            ))}
          </AppSelect>
        </Field>
        <Field label="Tanggal">
          <AppInput
            type="datetime-local"
            value={form.transaction_date}
            onChange={(event) => setForm({ ...form, transaction_date: event.target.value })}
            required
          />
        </Field>
        <Field label="Catatan">
          <AppTextarea
            rows={4}
            value={form.description ?? ""}
            placeholder="Contoh: makan siang, gaji, transportasi"
            onChange={(event) => setForm({ ...form, description: event.target.value })}
          />
        </Field>
        <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
          <AppButton type="button" variant="secondary" onClick={() => router.back()}>
            Batal
          </AppButton>
          <AppButton type="submit" disabled={saving}>
            {saving ? "Menyimpan..." : transaction ? "Simpan perubahan" : "Simpan transaksi"}
          </AppButton>
        </div>
      </form>
    </AppCard>
  );
}
