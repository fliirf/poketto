"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { AppLayout } from "@/components/layout/AppLayout";
import { PageHeader } from "@/components/layout/PageHeader";
import { CategoryForm } from "@/components/CategoryForm";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { Badge } from "@/components/ui/Badge";
import { EmptyState, ErrorState, LoadingState } from "@/components/ui/States";
import { useToast } from "@/components/ui/ToastProvider";
import { api } from "@/lib/api";
import { resolveDisplayCurrency } from "@/lib/currency";
import { formatCurrency, setStoredCurrency } from "@/lib/format";
import type { Category, DashboardSummary } from "@/types/poketto";

export default function CategoriesPage() {
  const toast = useToast();
  const [categories, setCategories] = useState<Category[]>([]);
  const [pendingDeleteId, setPendingDeleteId] = useState<number | null>(null);
  const [deletingId, setDeletingId] = useState<number | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [currency, setCurrency] = useState("IDR");
  const [currencyRate, setCurrencyRate] = useState(1);
  const [categoryBudgets, setCategoryBudgets] = useState<DashboardSummary["category_budgets"]>([]);

  const loadCategories = useCallback(async () => {
    setError("");
    setLoading(true);
    try {
      const [categoryData, settingsData, exchangeRateData, dashboardData] = await Promise.all([
        api.categories(),
        api.userSettings(),
        api.exchangeRates("IDR"),
        api.dashboard()
      ]);
      const displayCurrency = resolveDisplayCurrency(settingsData.user_settings.currency, exchangeRateData.exchange_rates);

      setCategories(categoryData.categories);
      setCategoryBudgets(dashboardData.category_budgets ?? []);
      setCurrency(displayCurrency.currency);
      setCurrencyRate(displayCurrency.rate);
      setStoredCurrency(displayCurrency.currency);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Kategori gagal dimuat.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadCategories();
  }, [loadCategories]);

  async function deleteCategory(id: number) {
    if (deletingId) return;
    setDeletingId(id);
    setError("");
    try {
      await api.deleteCategory(id);
      setCategories((current) => current.filter((category) => category.id !== id));
      window.dispatchEvent(new Event("poketto:notifications-refresh"));
      window.dispatchEvent(new Event("poketto:budget-refresh"));
      toast.success("Kategori berhasil dihapus.");
    } catch (err) {
      const message = err instanceof Error ? err.message : "Kategori gagal dihapus.";
      setError(message);
      toast.error(message);
    } finally {
      setDeletingId(null);
    }
  }

  return (
    <AppLayout>
      <PageHeader title="Kategori & Budget" description="Kelola kategori pemasukan, pengeluaran, dan budget bulanan." />
      <div className="grid gap-5 xl:grid-cols-[minmax(18rem,0.8fr)_minmax(0,1.2fr)]">
        <CategoryForm onSaved={loadCategories} />
        <AppCard>
          {loading ? <LoadingState /> : null}
          {error ? <ErrorState message={error} /> : null}
          {!loading && !categories.length ? <EmptyState title="Belum ada kategori" /> : null}
          <div className="grid gap-3">
            {categories.map((category) => {
              const budgetStatus = categoryBudgets.find((item) => item.category_id === category.id);
              const limitReached = category.type === "expense" && Number(budgetStatus?.percentage ?? 0) >= 100;

              return (
                <div key={category.id} className={`flex min-w-0 flex-col gap-3 rounded-2xl p-4 sm:flex-row sm:items-center sm:justify-between ${limitReached ? "border border-red-200 bg-red-50" : "bg-slate-50"}`}>
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="font-black text-slate-900">{category.name}</p>
                      <Badge tone={category.type}>{category.type === "income" ? "Pemasukan" : "Pengeluaran"}</Badge>
                      {limitReached ? <Badge tone="danger">Budget habis</Badge> : null}
                    </div>
                    <p className="mt-1 break-words text-sm text-slate-500">
                      Budget: {formatCurrency(Number(category.monthly_budget ?? 0) * currencyRate, currency)}
                      {budgetStatus ? (
                        <span className={limitReached ? "ml-2 font-bold text-red-600" : "ml-2 font-bold text-slate-400"}>
                          Terpakai {Math.round(Number(budgetStatus.percentage ?? 0))}%
                        </span>
                      ) : null}
                    </p>
                  </div>
                  <div className="flex shrink-0 flex-wrap justify-end gap-2">
                    <Link
                      href={`/categories/${category.id}/edit`}
                      className="inline-flex h-10 min-w-16 items-center justify-center rounded-xl border border-slate-200 bg-white px-4 text-xs font-extrabold text-slate-600 shadow-sm transition hover:border-poketto-200 hover:bg-poketto-50 hover:text-poketto-700"
                    >
                      Edit
                    </Link>
                    {pendingDeleteId === category.id ? (
                      <>
                        <AppButton
                          type="button"
                          variant="danger"
                          className="h-10 min-h-0 min-w-24 rounded-xl px-4 text-xs"
                          disabled={deletingId === category.id}
                          onClick={() => {
                            deleteCategory(category.id);
                            setPendingDeleteId(null);
                          }}
                        >
                          {deletingId === category.id ? "Menghapus..." : "Konfirmasi"}
                        </AppButton>
                        <AppButton
                          type="button"
                          variant="ghost"
                          className="h-10 min-h-0 min-w-16 rounded-xl px-4 text-xs"
                          onClick={() => setPendingDeleteId(null)}
                        >
                          Batal
                        </AppButton>
                      </>
                    ) : (
                      <AppButton
                        type="button"
                        variant="danger"
                        className="h-10 min-h-0 min-w-16 rounded-xl px-4 text-xs shadow-sm"
                        disabled={Boolean(deletingId)}
                        onClick={() => setPendingDeleteId(category.id)}
                      >
                        Hapus
                      </AppButton>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </AppCard>
      </div>
    </AppLayout>
  );
}
