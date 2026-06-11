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
const pieColors = ["#10b981", "#f59e0b", "#ef4444", "#8b5cf6", "#06b6d4", "#ec4899", "#64748b", "#3b82f6"];
type RateDirection = "idr-to-target" | "target-to-idr";

export default function DashboardPage() {
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [rates, setRates] = useState<ExchangeRate[]>([]);
  const [filters, setFilters] = useState<Filters>({});
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [ratesError, setRatesError] = useState("");
  const [ratesLoading, setRatesLoading] = useState(true);
  const [settingsCurrency, setSettingsCurrency] = useState("IDR");
  const [rateDirection, setRateDirection] = useState<RateDirection>("idr-to-target");

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
    Promise.all([api.dashboard(filters), api.categories(), api.userSettings()])
      .then(([dashboardData, categoryData, settingsData]) => {
        setSummary(dashboardData);
        setCategories(categoryData.categories);
        setSettingsCurrency(settingsData.user_settings.currency);
        setStoredCurrency(settingsData.user_settings.currency);
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
  const currency = settingsCurrency || summary?.currency || "IDR";
  const currencyRate = currency === "IDR"
    ? 1
    : Number(rates.find((rate) => rate.target_currency === currency && rate.base_currency === "IDR")?.rate ?? 0) || 1;
  const displayAmount = (value: number | string) => Number(value || 0) * currencyRate;
  const expenseRatio = summary && Number(summary.total_income) > 0
    ? (Number(summary.total_expense) / Number(summary.total_income)) * 100
    : 0;
  const categoryExpenseTotal = summary?.category_breakdown.reduce((total, item) => total + Number(item.total || 0), 0) ?? 0;
  const idrComparisonAmount = 1000;
  const formatRateAmount = (value: number, targetCurrency: string) =>
    `${value.toLocaleString("id-ID", {
      minimumFractionDigits: value > 0 && value < 1 ? 4 : 0,
      maximumFractionDigits: targetCurrency === "JPY" ? 2 : 6
    })} ${targetCurrency}`;

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
              <StatCard label="Saldo" value={displayAmount(summary.balance)} currency={currency} helper="Total pemasukan dikurangi pengeluaran" />
              <StatCard label="Pemasukan" value={displayAmount(summary.total_income)} currency={currency} tone="income" />
              <StatCard label="Pengeluaran" value={displayAmount(summary.total_expense)} currency={currency} tone="expense" />
              <StatCard
                label="Sisa budget bulanan"
                value={displayAmount(Math.max(0, Number(summary.monthly_budget) - Number(summary.total_expense)))}
                currency={currency}
                tone="warning"
                helper={`Budget: ${formatCurrency(displayAmount(summary.monthly_budget), currency)}`}
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

            <AppCard>
              <div className="mb-4 flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <h2 className="font-black text-slate-900">Ringkasan pemasukan vs pengeluaran</h2>
                  <p className="text-sm font-semibold text-slate-400">{summary.period?.label ?? "Periode terpilih"}</p>
                </div>
                <span
                  className={`rounded-full px-3 py-1 text-xs font-black ${
                    expenseRatio > 100
                      ? "bg-red-50 text-red-700"
                      : expenseRatio >= 80
                        ? "bg-amber-50 text-amber-700"
                        : "bg-emerald-50 text-emerald-700"
                  }`}
                >
                  Rasio {Math.round(expenseRatio)}%
                </span>
              </div>

              <div className="grid gap-4 lg:grid-cols-[1fr_0.9fr]">
                <div className="grid gap-4">
                  <div className="grid gap-3 sm:grid-cols-2">
                    <div className="rounded-2xl bg-emerald-50 p-4">
                      <p className="text-sm font-bold text-emerald-700">Total pemasukan</p>
                      <p className="mt-2 text-2xl font-black text-emerald-700">{formatCurrency(displayAmount(summary.total_income), currency)}</p>
                    </div>
                    <div className="rounded-2xl bg-red-50 p-4">
                      <p className="text-sm font-bold text-red-700">Total pengeluaran</p>
                      <p className="mt-2 text-2xl font-black text-red-700">{formatCurrency(displayAmount(summary.total_expense), currency)}</p>
                    </div>
                  </div>

                  <div>
                    <div className="mb-2 flex justify-between text-xs font-bold text-slate-400">
                      <span>Pengeluaran terhadap pemasukan</span>
                      <span>{Math.round(expenseRatio)}%</span>
                    </div>
                    <div className="h-4 overflow-hidden rounded-full bg-slate-100">
                      <div
                        className={`h-full rounded-full ${expenseRatio > 100 ? "bg-red-500" : expenseRatio >= 80 ? "bg-amber-500" : "bg-emerald-500"}`}
                        style={{ width: `${Math.min(100, Math.max(0, expenseRatio))}%` }}
                      />
                    </div>
                    {expenseRatio >= 80 ? (
                      <p className={`mt-2 text-xs font-bold ${expenseRatio > 100 ? "text-red-600" : "text-amber-600"}`}>
                        {expenseRatio > 100 ? "Pengeluaran melebihi pemasukan." : "Pengeluaran sudah cukup tinggi."}
                      </p>
                    ) : null}
                  </div>
                </div>

                <div className="rounded-2xl bg-slate-50 p-4">
                  <h3 className="mb-3 font-black text-slate-900">Komposisi pengeluaran</h3>
                  {summary.category_breakdown.length && categoryExpenseTotal > 0 ? (
                    <div className="grid gap-4 sm:grid-cols-[8rem_1fr] sm:items-center">
                      <div className="relative mx-auto h-32 w-32">
                        <svg viewBox="0 0 100 100" className="h-full w-full -rotate-90">
                          {(() => {
                            let currentAngle = 0;
                            return summary.category_breakdown.slice(0, 6).map((item, index) => {
                              const percentage = (Number(item.total) / categoryExpenseTotal) * 100;
                              const angle = (percentage / 100) * 360;
                              const startRad = (currentAngle * Math.PI) / 180;
                              const endRad = ((currentAngle + angle) * Math.PI) / 180;
                              const x1 = 50 + 36 * Math.cos(startRad);
                              const y1 = 50 + 36 * Math.sin(startRad);
                              const x2 = 50 + 36 * Math.cos(endRad);
                              const y2 = 50 + 36 * Math.sin(endRad);
                              const largeArc = angle > 180 ? 1 : 0;
                              const pathData = `M 50 50 L ${x1} ${y1} A 36 36 0 ${largeArc} 1 ${x2} ${y2} Z`;
                              currentAngle += angle;
                              return (
                                <path
                                  key={item.category}
                                  d={pathData}
                                  fill={pieColors[index % pieColors.length]}
                                  stroke="white"
                                  strokeWidth="2"
                                >
                                  <title>{`${item.category}: ${formatCurrency(displayAmount(item.total), currency)}`}</title>
                                </path>
                              );
                            });
                          })()}
                        </svg>
                        <div className="absolute inset-0 grid place-items-center">
                          <span className="rounded-full bg-white/90 px-2 py-1 text-xs font-black text-slate-500 shadow-sm">
                            {summary.category_breakdown.length}
                          </span>
                        </div>
                      </div>

                      <div className="grid gap-2 text-xs">
                        {summary.category_breakdown.slice(0, 6).map((item, index) => (
                          <div key={item.category} className="flex items-center justify-between gap-2">
                            <span className="flex min-w-0 items-center gap-2">
                              <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ backgroundColor: pieColors[index % pieColors.length] }} />
                              <span className="truncate font-bold text-slate-600">{item.category}</span>
                            </span>
                            <span className="shrink-0 font-black text-slate-800">{formatCurrency(displayAmount(item.total), currency)}</span>
                          </div>
                        ))}
                        {summary.category_breakdown.length > 6 ? (
                          <p className="text-center text-xs font-semibold text-slate-400">+{summary.category_breakdown.length - 6} kategori lainnya</p>
                        ) : null}
                      </div>
                    </div>
                  ) : (
                    <EmptyState title="Belum ada data pengeluaran" />
                  )}
                </div>
              </div>
            </AppCard>

            <div className="grid gap-5 xl:grid-cols-[1.4fr_1fr]">
              <AppCard>
                <div className="mb-4 flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <h2 className="font-black text-slate-900">Tren pengeluaran harian</h2>
                    <p className="text-sm font-semibold text-slate-400">
                      Total periode ini: <span className="text-poketto-700">{formatCurrency(displayAmount(summary.total_expense), currency)}</span>
                    </p>
                  </div>
                  <span className="rounded-full bg-slate-50 px-3 py-1 text-xs font-bold text-slate-400">
                    {summary.period?.label ?? "Periode terpilih"}
                  </span>
                </div>
                <div className="flex h-72 items-end gap-2 rounded-2xl bg-slate-50 p-4">
                  {summary.expense_trend.length ? (
                    summary.expense_trend.map((item) => {
                      const max = Math.max(...summary.expense_trend.map((trend) => Number(trend.total || 0)), 1);
                      const total = Number(item.total || 0);
                      const isHighest = total === max && max > 0;
                      return (
                        <div key={item.date} className="group relative flex flex-1 flex-col items-center gap-2">
                          <div className="pointer-events-none absolute -top-8 z-10 whitespace-nowrap rounded-lg bg-slate-900 px-2 py-1 text-xs font-bold text-white opacity-0 shadow-lg transition-opacity group-hover:opacity-100">
                            {formatCurrency(displayAmount(item.total), currency)}
                          </div>
                          <span className={`text-[0.65rem] font-bold ${total > 0 ? "text-poketto-700" : "text-slate-300"}`}>
                            {total > 0 ? formatCurrency(displayAmount(item.total), currency) : "-"}
                          </span>
                          <div
                            className={`w-full rounded-t-xl transition hover:brightness-110 ${isHighest ? "bg-poketto-700" : "bg-poketto-500"} ${total > 0 ? "" : "opacity-35"}`}
                            style={{ height: `${Math.max(8, (total / max) * 210)}px` }}
                            title={formatCurrency(displayAmount(item.total), currency)}
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
                            <span className={`font-bold ${budget.percentage >= 100 ? "text-red-600" : budget.percentage >= summary.budget_warning_threshold ? "text-amber-600" : "text-slate-500"}`}>
                              {Math.round(budget.percentage)}%
                            </span>
                          </div>
                          <div className="h-3 rounded-full bg-slate-100">
                            <div
                              className={`h-3 rounded-full ${budget.percentage >= 100 ? "bg-red-500" : budget.percentage >= summary.budget_warning_threshold ? "bg-amber-500" : "bg-poketto-500"}`}
                              style={{ width: `${Math.min(100, budget.percentage)}%` }}
                            />
                          </div>
                          <p className="mt-1 text-xs text-slate-400">
                            {formatCurrency(displayAmount(budget.spent), currency)} dari {formatCurrency(displayAmount(budget.monthly_budget), currency)}
                            {budget.percentage >= 100 ? (
                              <span className="ml-2 font-bold text-red-600">Melebihi budget.</span>
                            ) : budget.percentage >= summary.budget_warning_threshold ? (
                              <span className="ml-2 font-bold text-amber-600">Mendekati batas.</span>
                            ) : null}
                          </p>
                        </div>
                    ))
                  ) : (
                    <EmptyState title="Belum ada budget kategori" />
                  )}
                </div>
              </AppCard>
            </div>

            {summary.category_breakdown.length ? (
              <AppCard>
                <div className="mb-4 flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <h2 className="font-black text-slate-900">Detail pengeluaran per kategori</h2>
                    <p className="text-sm font-semibold text-slate-400">Urutan nominal pengeluaran pada periode ini.</p>
                  </div>
                  <span className="rounded-full bg-slate-50 px-3 py-1 text-xs font-bold text-slate-400">
                    {summary.period?.label ?? "Periode terpilih"}
                  </span>
                </div>
                <div className="grid gap-3 md:grid-cols-2">
                  {summary.category_breakdown.map((item, index) => {
                    const max = Math.max(...summary.category_breakdown.map((breakdown) => Number(breakdown.total || 0)), 1);
                    return (
                      <div key={item.category} className="rounded-2xl bg-slate-50 p-4">
                        <div className="mb-2 flex justify-between gap-3 text-sm">
                          <span className="truncate font-bold text-slate-700">{item.category}</span>
                          <span className="font-black text-slate-900">{formatCurrency(displayAmount(item.total), currency)}</span>
                        </div>
                        <div className="h-3 rounded-full bg-white">
                          <div
                            className="h-3 rounded-full"
                            style={{
                              width: `${Math.max(6, (Number(item.total) / max) * 100)}%`,
                              backgroundColor: pieColors[index % pieColors.length]
                            }}
                          />
                        </div>
                      </div>
                    );
                  })}
                </div>
              </AppCard>
            ) : null}

            <div className="grid gap-5 xl:grid-cols-[1.3fr_0.7fr]">
              <AppCard>
                <div className="mb-4 flex items-center justify-between">
                  <h2 className="font-black text-slate-900">Transaksi terbaru</h2>
                  <AppLinkButton href="/transactions" variant="secondary">
                    Lihat semua
                  </AppLinkButton>
                </div>
                <TransactionTable transactions={summary.recent_transactions} currency={currency} currencyRate={currencyRate} />
              </AppCard>

              <AppCard>
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h2 className="font-black text-slate-900">Kurs mata uang</h2>
                    <p className="mt-1 text-xs font-semibold text-slate-400">
                      Base {baseCurrency}
                      {updatedAt ? ` - Update ${formatDate(updatedAt)}` : ""}
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
                <div className="mt-4 grid grid-cols-2 rounded-2xl bg-slate-100 p-1 text-xs font-black text-slate-500">
                  <button
                    type="button"
                    onClick={() => setRateDirection("idr-to-target")}
                    className={`rounded-xl px-3 py-2 transition ${rateDirection === "idr-to-target" ? "bg-white text-poketto-700 shadow-sm" : "hover:text-slate-800"}`}
                  >
                    1.000 IDR ke kurs
                  </button>
                  <button
                    type="button"
                    onClick={() => setRateDirection("target-to-idr")}
                    className={`rounded-xl px-3 py-2 transition ${rateDirection === "target-to-idr" ? "bg-white text-poketto-700 shadow-sm" : "hover:text-slate-800"}`}
                  >
                    Kurs ke IDR
                  </button>
                </div>
                <div className="mt-4 grid gap-3">
                  {ratesLoading ? (
                    <div className="rounded-2xl bg-slate-50 px-4 py-5 text-sm font-semibold text-slate-500">Memuat kurs mata uang...</div>
                  ) : visibleRates.length ? (
                    visibleRates.map((rate) => {
                      const rateValue = Number(rate.rate || 0);
                      const forwardValue = idrComparisonAmount * rateValue;
                      const reverseValue = rateValue > 0 ? 1 / rateValue : 0;

                      return (
                        <div key={rate.target_currency} className="rounded-2xl bg-slate-50 px-4 py-3 text-sm">
                          <div className="flex items-center justify-between gap-3">
                            <span className="font-bold text-slate-600">
                              {rateDirection === "idr-to-target" ? `${idrComparisonAmount.toLocaleString("id-ID")} IDR` : `1 ${rate.target_currency}`}
                            </span>
                            <span className="text-right font-black text-slate-900">
                              {rateDirection === "idr-to-target"
                                ? formatRateAmount(forwardValue, rate.target_currency)
                                : formatCurrency(reverseValue, "IDR")}
                            </span>
                          </div>
                          <p className="mt-1 text-xs font-semibold text-slate-400">
                            {rateDirection === "idr-to-target"
                              ? `Perbandingan dari pecahan Rp ${idrComparisonAmount.toLocaleString("id-ID")}.`
                              : `Kebalikan: 1 ${rate.target_currency} setara rupiah.`}
                          </p>
                        </div>
                      );
                    })
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
