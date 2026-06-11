"use client";

import { useEffect, useMemo, useState } from "react";
import { AppLayout } from "@/components/layout/AppLayout";
import { PageHeader } from "@/components/layout/PageHeader";
import { FilterPanel } from "@/components/FilterPanel";
import { TransactionTable } from "@/components/TransactionTable";
import { AppCard } from "@/components/ui/AppCard";
import { AppLinkButton } from "@/components/ui/AppButton";
import { AppInput } from "@/components/ui/AppInput";
import { StatCard } from "@/components/ui/StatCard";
import { ErrorState, LoadingState } from "@/components/ui/States";
import { useToast } from "@/components/ui/ToastProvider";
import { api } from "@/lib/api";
import { setStoredCurrency } from "@/lib/format";
import type { Category, Filters, Transaction } from "@/types/poketto";

export default function TransactionsPage() {
  const toast = useToast();
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [filters, setFilters] = useState<Filters>({});
  const [search, setSearch] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [deletingId, setDeletingId] = useState<number | null>(null);
  const [currency, setCurrency] = useState("IDR");

  useEffect(() => {
    setLoading(true);
    setError("");
    Promise.all([api.transactions(filters), api.categories(), api.userSettings()])
      .then(([transactionData, categoryData, settingsData]) => {
        setTransactions(transactionData.transactions);
        setCategories(categoryData.categories);
        setCurrency(settingsData.user_settings.currency);
        setStoredCurrency(settingsData.user_settings.currency);
      })
      .catch((err) => setError(err instanceof Error ? err.message : "Transaksi gagal dimuat."))
      .finally(() => setLoading(false));
  }, [filters]);

  const filtered = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return transactions;
    return transactions.filter((transaction) => {
      const category = transaction.category?.name ?? transaction.category_name ?? "";
      return [category, transaction.description, transaction.location_name]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(keyword));
    });
  }, [search, transactions]);

  const income = filtered.filter((transaction) => transaction.type === "income").reduce((total, item) => total + Number(item.amount), 0);
  const expense = filtered.filter((transaction) => transaction.type === "expense").reduce((total, item) => total + Number(item.amount), 0);
  const pdfPeriodLabel = describePdfPeriod(filters);

  async function deleteTransaction(id: number) {
    if (deletingId) return;
    setDeletingId(id);
    setError("");
    try {
      await api.deleteTransaction(id);
      setTransactions((current) => current.filter((transaction) => transaction.id !== id));
      toast.success("Transaksi berhasil dihapus.");
    } catch (err) {
      const message = err instanceof Error ? err.message : "Transaksi gagal dihapus.";
      setError(message);
      toast.error(message);
    } finally {
      setDeletingId(null);
    }
  }

  async function exportPdf() {
    setExporting(true);
    setError("");
    try {
      const { blob, filename } = await api.exportTransactionsPdf(filters);
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Export PDF gagal.");
    } finally {
      setExporting(false);
    }
  }

  return (
    <AppLayout>
      <PageHeader
        title="Riwayat Transaksi"
        description="Cari, filter, edit, dan hapus transaksi dari API Laravel."
        actions={
          <>
            <button
              type="button"
              onClick={exportPdf}
              disabled={exporting}
              title={`PDF mengikuti filter: ${pdfPeriodLabel}`}
              className="min-h-11 rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm font-bold text-slate-700 transition hover:border-poketto-200 hover:text-poketto-700 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {exporting ? "Menyiapkan PDF..." : "Export PDF"}
            </button>
            <AppLinkButton href="/transactions/new">Tambah transaksi</AppLinkButton>
          </>
        }
      />

      <div className="grid gap-5">
        <AppCard>
          <div className="grid gap-4">
            <div>
              <h2 className="text-base font-black text-slate-900">Filter transaksi</h2>
              <p className="mt-1 text-sm font-semibold text-slate-400">
                Pilih rentang Mulai/Sampai atau Bulan. Export PDF akan mengikuti filter aktif.
              </p>
            </div>
            <AppInput
              type="search"
              placeholder="Cari kategori, catatan, atau lokasi..."
              value={search}
              onChange={(event) => setSearch(event.target.value)}
            />
            <FilterPanel filters={filters} categories={categories} onChange={setFilters} onReset={() => setFilters({})} />
            <div className="rounded-2xl bg-poketto-50 px-4 py-3 text-sm font-bold text-poketto-700">
              Rentang export PDF: {pdfPeriodLabel}
            </div>
          </div>
        </AppCard>

        <div className="grid gap-4 md:grid-cols-3">
          <StatCard label="Pemasukan" value={income} currency={currency} tone="income" />
          <StatCard label="Pengeluaran" value={expense} currency={currency} tone="expense" />
          <StatCard label="Sisa" value={income - expense} currency={currency} />
        </div>

        {loading ? <LoadingState /> : null}
        {error ? <ErrorState message={error} /> : null}

        {!loading ? (
          <AppCard>
            <TransactionTable transactions={filtered} onDelete={deleteTransaction} deletingId={deletingId} />
          </AppCard>
        ) : null}
      </div>
    </AppLayout>
  );
}

function describePdfPeriod(filters: Filters) {
  const parts: string[] = [];

  if (filters.month) {
    const [year, month] = filters.month.split("-");
    const date = new Date(Number(year), Number(month) - 1, 1);
    parts.push(date.toLocaleDateString("id-ID", { month: "long", year: "numeric" }));
  }

  if (filters.start_date || filters.end_date) {
    parts.push(`${formatDateInput(filters.start_date) ?? "Awal"} sampai ${formatDateInput(filters.end_date) ?? "Sekarang"}`);
  }

  if (filters.type) {
    parts.push(filters.type === "income" ? "Pemasukan" : "Pengeluaran");
  }

  if (filters.category_id) {
    parts.push("Kategori terpilih");
  }

  return parts.length ? parts.join(" - ") : "Semua transaksi";
}

function formatDateInput(value?: string) {
  if (!value) return null;
  const [year, month, day] = value.split("-");
  if (!year || !month || !day) return value;

  return new Date(Number(year), Number(month) - 1, Number(day)).toLocaleDateString("id-ID", {
    day: "2-digit",
    month: "short",
    year: "numeric"
  });
}
