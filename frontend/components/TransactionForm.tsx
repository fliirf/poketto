"use client";

import { FormEvent, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { AppInput, AppTextarea, Field } from "@/components/ui/AppInput";
import { AppSelect } from "@/components/ui/AppSelect";
import { ErrorState } from "@/components/ui/States";
import { useToast } from "@/components/ui/ToastProvider";
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
  const toast = useToast();
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState<TransactionPayload>({
    type: transaction?.type ?? "expense",
    category_id: transaction?.category_id ?? null,
    amount: transaction?.amount ?? 0,
    transaction_date: toDateTimeLocal(transaction?.transaction_date ?? transaction?.date),
    description: transaction?.description ?? ""
  });
  const availableCategories = useMemo(
    () => categories.filter((category) => category.type === form.type),
    [categories, form.type]
  );

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (saving) return;
    setError("");
    if (!form.category_id) {
      const message = "Kategori wajib dipilih.";
      setError(message);
      toast.error(message);
      return;
    }
    if (!form.amount || Number(form.amount) <= 0) {
      const message = "Nominal wajib diisi.";
      setError(message);
      toast.error(message);
      return;
    }
    if (!form.transaction_date) {
      const message = "Tanggal transaksi wajib diisi.";
      setError(message);
      toast.error(message);
      return;
    }

    setSaving(true);
    try {
      if (transaction) {
        await api.updateTransaction(transaction.id, form);
        toast.success("Transaksi berhasil diperbarui.");
      } else {
        await api.createTransaction(form);
        toast.success(form.type === "income" ? "Berhasil tambah pemasukan." : "Berhasil tambah pengeluaran.");
      }
      router.push("/transactions");
      router.refresh();
    } catch (err) {
      const message = err instanceof Error ? err.message : "Gagal menyimpan transaksi. Periksa kembali data yang diisi.";
      setError(message);
      toast.error(message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <AppCard className="mx-auto max-w-2xl">
      <form onSubmit={submit} className="grid gap-4">
        {error ? <ErrorState message={error} /> : null}
        <Field label="Tipe">
          <AppSelect
            value={form.type}
            onChange={(event) => {
              const nextType = event.target.value as TransactionType;
              const currentCategory = categories.find((category) => category.id === form.category_id);
              setForm({
                ...form,
                type: nextType,
                category_id: currentCategory?.type === nextType ? form.category_id : null
              });
            }}
          >
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
            required
          >
            <option value="">Pilih kategori</option>
            {availableCategories.map((category) => (
              <option key={category.id} value={category.id}>
                {category.name} ({category.type === "income" ? "Pemasukan" : "Pengeluaran"})
              </option>
            ))}
          </AppSelect>
          {!availableCategories.length ? (
            <span className="text-xs font-semibold text-red-600">
              Belum ada kategori {form.type === "income" ? "pemasukan" : "pengeluaran"}. Tambahkan kategori dulu.
            </span>
          ) : null}
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
