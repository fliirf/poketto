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

  useEffect(() => {
    setLoading(true);
    setError("");
    Promise.all([api.transactions(filters), api.categories()])
      .then(([transactionData, categoryData]) => {
        setTransactions(transactionData.transactions);
        setCategories(categoryData.categories);
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
            <AppInput
              type="search"
              placeholder="Cari kategori, catatan, atau lokasi..."
              value={search}
              onChange={(event) => setSearch(event.target.value)}
            />
            <FilterPanel filters={filters} categories={categories} onChange={setFilters} onReset={() => setFilters({})} />
          </div>
        </AppCard>

        <div className="grid gap-4 md:grid-cols-3">
          <StatCard label="Pemasukan" value={income} tone="income" />
          <StatCard label="Pengeluaran" value={expense} tone="expense" />
          <StatCard label="Sisa" value={income - expense} />
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
