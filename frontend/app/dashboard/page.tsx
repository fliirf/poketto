"use client";

import { useEffect, useState } from "react";
import { AppLayout } from "@/components/layout/AppLayout";
import { PageHeader } from "@/components/layout/PageHeader";
import { FilterPanel } from "@/components/FilterPanel";
import { TransactionTable } from "@/components/TransactionTable";
import { AppCard } from "@/components/ui/AppCard";
import { AppLinkButton } from "@/components/ui/AppButton";
import { StatCard } from "@/components/ui/StatCard";
import { EmptyState, ErrorState, LoadingState } from "@/components/ui/States";
import { api } from "@/lib/api";
import { formatCurrency, formatDate, setStoredCurrency } from "@/lib/format";
import type { Category, DashboardSummary, ExchangeRate, Filters } from "@/types/poketto";

const importantCurrencies = ["USD", "EUR", "SGD", "JPY"];

export default function DashboardPage() {
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [rates, setRates] = useState<ExchangeRate[]>([]);
  const [filters, setFilters] = useState<Filters>({});
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [ratesError, setRatesError] = useState("");
  const [ratesLoading, setRatesLoading] = useState(true);

  function loadRates() {
    setRatesLoading(true);
    setRatesError("");
    api
      .exchangeRates("IDR")
      .then((rateData) => setRates(rateData.exchange_rates ?? []))
      .catch((err) => {
        setRates([]);
        setRatesError(err instanceof Error ? err.message : "Kurs mata uang gagal dimuat.");
      })
      .finally(() => setRatesLoading(false));
  }

  useEffect(() => {
    setLoading(true);
    setError("");
    Promise.all([api.dashboard(filters), api.categories()])
      .then(([dashboardData, categoryData]) => {
        setSummary(dashboardData);
        setCategories(categoryData.categories);
        setStoredCurrency(dashboardData.currency ?? "IDR");
      })
      .catch((err) => setError(err instanceof Error ? err.message : "Dashboard gagal dimuat."))
      .finally(() => setLoading(false));
  }, [filters]);

  useEffect(() => {
    loadRates();
  }, []);

  const orderedRates = importantCurrencies
    .map((currency) => rates.find((rate) => rate.target_currency === currency))
    .filter((rate): rate is ExchangeRate => Boolean(rate));
  const visibleRates = orderedRates.length ? orderedRates : rates.slice(0, 5);
  const baseCurrency = visibleRates[0]?.base_currency ?? "IDR";
  const updatedAt = visibleRates.find((rate) => rate.fetched_at)?.fetched_at;
  const currency = summary?.currency ?? "IDR";

  return (
    <AppLayout>
      <PageHeader
        title="Dashboard"
        description="Ringkasan saldo, pengeluaran, budget, dan aktivitas terbaru Poketto."
        actions={<AppLinkButton href="/transactions/new">Tambah transaksi</AppLinkButton>}
      />

      <div className="grid gap-5">
        <AppCard>
          <div className="mb-4 flex flex-col gap-1">
            <h2 className="text-base font-black text-slate-900">Filter dashboard</h2>
            <p className="text-sm font-semibold text-slate-400">Atur periode, kategori, dan tipe transaksi yang ingin dilihat.</p>
          </div>
          <FilterPanel filters={filters} categories={categories} onChange={setFilters} onReset={() => setFilters({})} />
        </AppCard>

        {loading ? <LoadingState /> : null}
        {error ? <ErrorState message={error} /> : null}

        {summary && !loading ? (
          <>
            <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
              <StatCard label="Saldo" value={summary.balance} currency={currency} helper="Total pemasukan dikurangi pengeluaran" />
              <StatCard label="Pemasukan" value={summary.total_income} currency={currency} tone="income" />
              <StatCard label="Pengeluaran" value={summary.total_expense} currency={currency} tone="expense" />
              <StatCard
                label="Sisa budget bulanan"
                value={Math.max(0, Number(summary.monthly_budget) - Number(summary.total_expense))}
                currency={currency}
                tone="warning"
                helper={`Budget: ${formatCurrency(summary.monthly_budget, currency)}`}
              />
            </div>

            {summary.alerts?.length ? (
              <AppCard className="border-amber-100 bg-amber-50">
                <p className="font-black text-amber-800">Peringatan budget</p>
                <div className="mt-3 grid gap-2">
                  {summary.alerts.map((alert, index) => (
                    <p key={index} className="rounded-2xl bg-white/70 px-4 py-3 text-sm font-semibold text-amber-800">
                      {typeof alert === "string" ? alert : alert.message ?? "Budget perlu diperhatikan."}
                    </p>
                  ))}
                </div>
              </AppCard>
            ) : null}

            <div className="grid gap-5 xl:grid-cols-[1.4fr_1fr]">
              <AppCard>
                <div className="mb-4 flex items-center justify-between">
                  <h2 className="font-black text-slate-900">Tren pengeluaran</h2>
                  <span className="rounded-full bg-slate-50 px-3 py-1 text-xs font-bold text-slate-400">
                    {summary.period?.label ?? "Periode terpilih"}
                  </span>
                </div>
                <div className="flex h-64 items-end gap-2 rounded-2xl bg-slate-50 p-4">
                  {summary.expense_trend.length ? (
                    summary.expense_trend.map((item) => {
                      const max = Math.max(...summary.expense_trend.map((trend) => Number(trend.total || 0)), 1);
                      return (
                        <div key={item.date} className="flex flex-1 flex-col items-center gap-2">
                          <div
                            className="w-full rounded-t-xl bg-poketto-500"
                            style={{ height: `${Math.max(8, (Number(item.total) / max) * 190)}px` }}
                            title={formatCurrency(item.total, currency)}
                          />
                          <span className="text-[0.7rem] font-bold text-slate-400">{item.label ?? item.date.slice(5)}</span>
                        </div>
                      );
                    })
                  ) : (
                    <EmptyState title="Belum ada tren" />
                  )}
                </div>
              </AppCard>

              <AppCard>
                <h2 className="font-black text-slate-900">Budget kategori</h2>
                <div className="mt-4 grid gap-4">
                  {summary.category_budgets.length ? (
                    summary.category_budgets.map((budget) => (
                      <div key={budget.category_id}>
                        <div className="mb-2 flex justify-between text-sm">
                          <span className="font-bold text-slate-700">{budget.category_name}</span>
                          <span className="text-slate-500">{Math.round(budget.percentage)}%</span>
                        </div>
                        <div className="h-3 rounded-full bg-slate-100">
                          <div className="h-3 rounded-full bg-poketto-500" style={{ width: `${Math.min(100, budget.percentage)}%` }} />
                        </div>
                        <p className="mt-1 text-xs text-slate-400">
                          {formatCurrency(budget.spent, currency)} dari {formatCurrency(budget.monthly_budget, currency)}
                        </p>
                      </div>
                    ))
                  ) : (
                    <EmptyState title="Belum ada budget kategori" />
                  )}
                </div>
              </AppCard>
            </div>

            <div className="grid gap-5 xl:grid-cols-[1.3fr_0.7fr]">
              {summary.category_breakdown.length ? (
                <AppCard>
                  <h2 className="font-black text-slate-900">Visualisasi pengeluaran</h2>
                  <div className="mt-4 grid gap-3">
                    {summary.category_breakdown.map((item) => {
                      const max = Math.max(...summary.category_breakdown.map((breakdown) => Number(breakdown.total || 0)), 1);
                      return (
                        <div key={item.category}>
                          <div className="mb-1 flex justify-between gap-3 text-sm">
                            <span className="truncate font-bold text-slate-700">{item.category}</span>
                            <span className="font-black text-slate-900">{formatCurrency(item.total, currency)}</span>
                          </div>
                          <div className="h-3 rounded-full bg-slate-100">
                            <div className="h-3 rounded-full bg-poketto-500" style={{ width: `${Math.max(6, (Number(item.total) / max) * 100)}%` }} />
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </AppCard>
              ) : null}
            </div>

            <div className="grid gap-5 xl:grid-cols-[1.3fr_0.7fr]">
              <AppCard>
                <div className="mb-4 flex items-center justify-between">
                  <h2 className="font-black text-slate-900">Transaksi terbaru</h2>
                  <AppLinkButton href="/transactions" variant="secondary">
                    Lihat semua
                  </AppLinkButton>
                </div>
                <TransactionTable transactions={summary.recent_transactions} />
              </AppCard>

              <AppCard>
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h2 className="font-black text-slate-900">Kurs mata uang</h2>
                    <p className="mt-1 text-xs font-semibold text-slate-400">
                      Base {baseCurrency}
                      {updatedAt ? ` · Update ${formatDate(updatedAt)}` : ""}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={loadRates}
                    disabled={ratesLoading}
                    className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-bold text-slate-600 transition hover:text-poketto-700 disabled:opacity-60"
                  >
                    Coba lagi
                  </button>
                </div>
                <div className="mt-4 grid gap-3">
                  {ratesLoading ? (
                    <div className="rounded-2xl bg-slate-50 px-4 py-5 text-sm font-semibold text-slate-500">Memuat kurs mata uang...</div>
                  ) : visibleRates.length ? (
                    visibleRates.map((rate) => (
                        <div key={rate.target_currency} className="flex justify-between rounded-2xl bg-slate-50 px-4 py-3 text-sm">
                          <span className="font-bold text-slate-600">{rate.target_currency}</span>
                          <span className="font-black text-slate-900">{Number(rate.rate).toLocaleString("id-ID", { maximumFractionDigits: 8 })}</span>
                        </div>
                      ))
                  ) : (
                    <EmptyState
                      title="Kurs mata uang belum tersedia"
                      description={ratesError || "Tambahkan EXCHANGE_RATE_API_KEY atau tunggu data kurs tersimpan dari backend."}
                    />
                  )}
                </div>
              </AppCard>
            </div>
          </>
        ) : null}
      </div>
    </AppLayout>
  );
}
