"use client";

import { useEffect, useMemo, useState } from "react";
import { AppLayout } from "@/components/layout/AppLayout";
import { PageHeader } from "@/components/layout/PageHeader";
import { TransactionTable } from "@/components/TransactionTable";
import { AppCard } from "@/components/ui/AppCard";
import { AppButton, AppLinkButton } from "@/components/ui/AppButton";
import { AppInput } from "@/components/ui/AppInput";
import { AppSelect } from "@/components/ui/AppSelect";
import { StatCard } from "@/components/ui/StatCard";
import { EmptyState, ErrorState, LoadingState } from "@/components/ui/States";
import { api } from "@/lib/api";
import { resolveDisplayCurrency } from "@/lib/currency";
import { formatCurrency, formatDate, setStoredCurrency } from "@/lib/format";
import type { Category, DashboardSummary, ExchangeRate, Filters } from "@/types/poketto";

const importantCurrencies = ["USD", "EUR", "SGD", "JPY"];
const pieColors = ["#10b981", "#f59e0b", "#ef4444", "#8b5cf6", "#06b6d4", "#ec4899", "#64748b", "#3b82f6"];
type RateDirection = "idr-to-target" | "target-to-idr";
type PeriodMode = "today" | "week" | "month" | "year" | "custom";
type ResolvedTrendMode = "daily" | "weekly" | "monthly";
type TrendPoint = {
  key: string;
  label: string;
  tooltipLabel: string;
  total: number;
  date?: string;
};

const defaultPeriodMode: PeriodMode = "month";

function padDatePart(value: number) {
  return String(value).padStart(2, "0");
}

function formatDateParam(date: Date) {
  return `${date.getFullYear()}-${padDatePart(date.getMonth() + 1)}-${padDatePart(date.getDate())}`;
}

function currentMonthParam() {
  const now = new Date();
  return `${now.getFullYear()}-${padDatePart(now.getMonth() + 1)}`;
}

function periodFilters(mode: PeriodMode, customRange: { start_date?: string; end_date?: string }): Filters {
  const now = new Date();

  if (mode === "today") {
    const today = formatDateParam(now);
    return { start_date: today, end_date: today };
  }

  if (mode === "week") {
    const start = new Date(now);
    const day = start.getDay() || 7;
    start.setDate(start.getDate() - day + 1);
    const end = new Date(start);
    end.setDate(start.getDate() + 6);

    return { start_date: formatDateParam(start), end_date: formatDateParam(end) };
  }

  if (mode === "year") {
    return {
      start_date: `${now.getFullYear()}-01-01`,
      end_date: `${now.getFullYear()}-12-31`
    };
  }

  if (mode === "custom") {
    return {
      start_date: customRange.start_date,
      end_date: customRange.end_date
    };
  }

  return { month: currentMonthParam() };
}

function buildDashboardFilters(
  mode: PeriodMode,
  customRange: { start_date?: string; end_date?: string },
  extra: Pick<Filters, "category_id" | "type">
): Filters {
  return {
    ...periodFilters(mode, customRange),
    category_id: extra.category_id || undefined,
    type: extra.type || undefined
  };
}

function dateFromParam(value: string) {
  const [year, month, day] = value.split("-").map(Number);
  return new Date(year, month - 1, day);
}

function shortDateLabel(value: string) {
  return dateFromParam(value).toLocaleDateString("id-ID", { day: "2-digit", month: "short" });
}

function shortMonthLabel(value: string) {
  return dateFromParam(`${value}-01`).toLocaleDateString("id-ID", { month: "short", year: "2-digit" });
}

function resolveTrendMode(points: Array<{ date: string }>): ResolvedTrendMode {
  if (points.length > 90) return "monthly";
  if (points.length > 31) return "weekly";
  return "daily";
}

function aggregateTrend(points: Array<{ date: string; label?: string; total: number }>, mode: ResolvedTrendMode): TrendPoint[] {
  if (mode === "daily") {
    return points.map((point) => ({
      key: point.date,
      date: point.date,
      label: shortDateLabel(point.date),
      tooltipLabel: shortDateLabel(point.date),
      total: Number(point.total || 0)
    }));
  }

  if (mode === "monthly") {
    const grouped = new Map<string, TrendPoint>();
    points.forEach((point) => {
      const month = point.date.slice(0, 7);
      const current = grouped.get(month);
      grouped.set(month, {
        key: month,
        label: shortMonthLabel(month),
        tooltipLabel: shortMonthLabel(month),
        total: (current?.total ?? 0) + Number(point.total || 0)
      });
    });

    return Array.from(grouped.values());
  }

  const grouped = new Map<string, TrendPoint>();
  points.forEach((point, index) => {
    const weekIndex = Math.floor(index / 7) + 1;
    const key = `week-${weekIndex}`;
    const current = grouped.get(key);
    const label = `Minggu ${weekIndex}`;
    grouped.set(key, {
      key,
      label,
      tooltipLabel: current ? `${shortDateLabel(current.date ?? point.date)} - ${shortDateLabel(point.date)}` : shortDateLabel(point.date),
      date: current?.date ?? point.date,
      total: (current?.total ?? 0) + Number(point.total || 0)
    });
  });

  return Array.from(grouped.values());
}

export default function DashboardPage() {
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [rates, setRates] = useState<ExchangeRate[]>([]);
  const [periodMode, setPeriodMode] = useState<PeriodMode>(defaultPeriodMode);
  const [customRange, setCustomRange] = useState<{ start_date?: string; end_date?: string }>({});
  const [filterOptions, setFilterOptions] = useState<Pick<Filters, "category_id" | "type">>({});
  const [advancedOpen, setAdvancedOpen] = useState(false);
  const filters = useMemo(
    () => buildDashboardFilters(periodMode, customRange, filterOptions),
    [customRange, filterOptions, periodMode]
  );
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [ratesError, setRatesError] = useState("");
  const [ratesLoading, setRatesLoading] = useState(true);
  const [settingsCurrency, setSettingsCurrency] = useState("IDR");
  const [rateDirection, setRateDirection] = useState<RateDirection>("idr-to-target");

  function resetFilters() {
    setPeriodMode(defaultPeriodMode);
    setCustomRange({});
    setFilterOptions({});
    setAdvancedOpen(false);
  }

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
        window.dispatchEvent(new Event("poketto:notifications-refresh"));
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
  const displayCurrency = resolveDisplayCurrency(settingsCurrency || summary?.currency, rates);
  const currency = displayCurrency.currency;
  const currencyRate = displayCurrency.rate;
  const displayAmount = (value: number | string) => Number(value || 0) * currencyRate;
  const rawDailyBudget = Number(summary?.daily_budget ?? 0);
  const todayKey = formatDateParam(new Date());
  const todayTrendSpent = Number(summary?.expense_trend.find((item) => item.date === todayKey)?.total ?? 0);
  const rawDailySpent = Math.max(Number(summary?.daily_expense ?? 0), todayTrendSpent);
  const rawDailyRemaining = Math.max(0, rawDailyBudget - rawDailySpent);
  const dailyBudgetUsed = rawDailyBudget > 0 ? Math.min(100, (rawDailySpent / rawDailyBudget) * 100) : 0;
  const rawMonthlyBudget = Number(summary?.monthly_budget ?? 0);
  const rawMonthlySpent = Number(summary?.monthly_expense ?? summary?.total_expense ?? 0);
  const rawMonthlyRemaining = summary?.monthly_budget_remaining ?? Math.max(0, rawMonthlyBudget - rawMonthlySpent);
  const monthlyBudgetUsed = summary?.monthly_budget_percentage ?? (rawMonthlyBudget > 0 ? Math.min(100, (rawMonthlySpent / rawMonthlyBudget) * 100) : 0);
  const dailyLimitReached = dailyBudgetUsed >= 100;
  const monthlyLimitReached = monthlyBudgetUsed >= 100;
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
        <DashboardQuickFilter
          periodMode={periodMode}
          customRange={customRange}
          filterOptions={filterOptions}
          categories={categories}
          advancedOpen={advancedOpen}
          onPeriodModeChange={(nextMode) => {
            setPeriodMode(nextMode);
            if (nextMode === "custom") {
              setAdvancedOpen(true);
            }
          }}
          onCustomRangeChange={setCustomRange}
          onFilterOptionsChange={setFilterOptions}
          onAdvancedToggle={() => setAdvancedOpen((current) => !current)}
          onReset={resetFilters}
        />

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
                value={displayAmount(rawMonthlyRemaining)}
                currency={currency}
                tone="warning"
                helper={`Budget: ${formatCurrency(displayAmount(summary.monthly_budget), currency)}`}
              />
            </div>

            <div className="grid gap-5 xl:grid-cols-2">
              <BudgetProgressCard
                title="Daily budget"
                spent={displayAmount(rawDailySpent)}
                budget={displayAmount(rawDailyBudget)}
                remaining={displayAmount(rawDailyRemaining)}
                percentage={dailyBudgetUsed}
                currency={currency}
                danger={dailyLimitReached}
              />
              <BudgetProgressCard
                title="Monthly budget"
                spent={displayAmount(rawMonthlySpent)}
                budget={displayAmount(rawMonthlyBudget)}
                remaining={displayAmount(rawMonthlyRemaining)}
                percentage={monthlyBudgetUsed}
                currency={currency}
                danger={monthlyLimitReached}
              />
            </div>

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

              <div className="grid gap-4 xl:grid-cols-[minmax(0,1fr)_minmax(18rem,0.9fr)]">
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

            <div className="grid gap-5 xl:grid-cols-[minmax(0,1.4fr)_minmax(18rem,1fr)]">
              <AppCard>
                <ExpenseTrendChart
                  points={summary.expense_trend}
                  totalExpense={displayAmount(summary.total_expense)}
                  currency={currency}
                  periodLabel={summary.period?.label ?? "Periode terpilih"}
                  displayAmount={displayAmount}
                />
              </AppCard>

              <AppCard>
                <h2 className="font-black text-slate-900">Budget kategori</h2>
                <div className="mt-4 grid gap-4">
                  {summary.category_budgets.length ? (
                    summary.category_budgets.map((budget) => {
                      const percentage = Number(budget.percentage || 0);
                      const cappedPercentage = Math.min(100, Math.max(0, percentage));

                      return (
                        <div key={budget.category_id}>
                          <div className="mb-2 flex justify-between gap-3 text-sm">
                            <span className="min-w-0 truncate font-bold text-slate-700">{budget.category_name}</span>
                            <span className={`font-bold ${budget.percentage >= 100 ? "text-red-600" : budget.percentage >= summary.budget_warning_threshold ? "text-amber-600" : "text-slate-500"}`}>
                              {Math.round(budget.percentage)}%
                            </span>
                          </div>
                          <div className="h-3 rounded-full bg-slate-100">
                            <div
                              className={`h-3 rounded-full ${budget.percentage >= 100 ? "bg-red-500" : budget.percentage >= summary.budget_warning_threshold ? "bg-amber-500" : "bg-poketto-500"}`}
                              style={{ width: `${cappedPercentage}%` }}
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
                      );
                    })
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

            <div className="grid gap-5 2xl:grid-cols-[minmax(0,1.35fr)_minmax(24rem,0.8fr)]">
              <AppCard>
                <div className="mb-3 flex items-center justify-between gap-3">
                  <div>
                    <h2 className="font-black text-slate-900">Transaksi terbaru</h2>
                    <p className="mt-1 text-xs font-semibold text-slate-400">Aktivitas terakhir yang tercatat.</p>
                  </div>
                  <AppLinkButton href="/transactions" variant="secondary">
                    Lihat semua
                  </AppLinkButton>
                </div>
                <div className="max-h-[24rem] overflow-y-auto pr-1">
                  <TransactionTable transactions={summary.recent_transactions} currency={currency} currencyRate={currencyRate} compact showActions={false} />
                </div>
              </AppCard>

              <AppCard className="min-w-0 2xl:min-w-96">
                <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                  <div className="min-w-0">
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
                    className="h-9 shrink-0 rounded-xl border border-slate-200 bg-white px-3 text-xs font-bold text-slate-600 transition hover:text-poketto-700 disabled:opacity-60"
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
                <div className="mt-4 grid gap-2">
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

function DashboardQuickFilter({
  periodMode,
  customRange,
  filterOptions,
  categories,
  advancedOpen,
  onPeriodModeChange,
  onCustomRangeChange,
  onFilterOptionsChange,
  onAdvancedToggle,
  onReset
}: {
  periodMode: PeriodMode;
  customRange: { start_date?: string; end_date?: string };
  filterOptions: Pick<Filters, "category_id" | "type">;
  categories: Category[];
  advancedOpen: boolean;
  onPeriodModeChange: (mode: PeriodMode) => void;
  onCustomRangeChange: (range: { start_date?: string; end_date?: string }) => void;
  onFilterOptionsChange: (filters: Pick<Filters, "category_id" | "type">) => void;
  onAdvancedToggle: () => void;
  onReset: () => void;
}) {
  const selectedType = filterOptions.type ?? "";
  const visibleCategories = selectedType
    ? categories.filter((category) => category.type === selectedType)
    : categories;

  function updateType(type: Filters["type"]) {
    const selectedCategory = categories.find((category) => String(category.id) === filterOptions.category_id);
    onFilterOptionsChange({
      ...filterOptions,
      type,
      category_id: type && selectedCategory?.type !== type ? "" : filterOptions.category_id
    });
  }

  return (
    <div className="grid gap-3">
        <div className="flex flex-col gap-2 rounded-3xl border border-white/80 bg-white/80 p-3 shadow-sm sm:flex-row sm:flex-wrap sm:items-center">
        <CompactField label="Periode">
          <AppSelect
            value={periodMode}
            onChange={(event) => onPeriodModeChange(event.target.value as PeriodMode)}
            className="min-h-10 w-full min-w-0 rounded-xl px-3 text-xs font-bold sm:w-40"
          >
            <option value="today">Hari ini</option>
            <option value="week">Minggu ini</option>
            <option value="month">Bulan ini</option>
            <option value="year">Tahun ini</option>
            <option value="custom">Custom</option>
          </AppSelect>
        </CompactField>

        <CompactField label="Kategori">
          <AppSelect
            value={filterOptions.category_id ?? ""}
            onChange={(event) => onFilterOptionsChange({ ...filterOptions, category_id: event.target.value })}
            className="min-h-10 w-full min-w-0 rounded-xl px-3 text-xs font-bold sm:w-44"
          >
            <option value="">Semua</option>
            {visibleCategories.map((category) => (
              <option key={category.id} value={category.id}>
                {category.name}
              </option>
            ))}
          </AppSelect>
        </CompactField>

        <CompactField label="Tipe">
          <AppSelect
            value={selectedType}
            onChange={(event) => updateType(event.target.value as Filters["type"])}
            className="min-h-10 w-full min-w-0 rounded-xl px-3 text-xs font-bold sm:w-36"
          >
            <option value="">Semua</option>
            <option value="income">Pemasukan</option>
            <option value="expense">Pengeluaran</option>
          </AppSelect>
        </CompactField>

        <div className="grid grid-cols-2 gap-2 sm:ml-auto sm:flex sm:items-end">
          <AppButton type="button" variant="secondary" className="min-h-10 rounded-xl px-3 text-xs" onClick={onAdvancedToggle}>
            Filter lanjutan
          </AppButton>
          <AppButton type="button" variant="ghost" className="min-h-10 rounded-xl px-3 text-xs" onClick={onReset}>
            Reset
          </AppButton>
        </div>
      </div>

      {advancedOpen ? (
        <div className="grid gap-3 rounded-3xl border border-slate-100 bg-white p-4 shadow-sm md:grid-cols-[1fr_1fr_auto] md:items-end">
          <CompactField label={periodMode === "custom" ? "Mulai" : "Mulai custom"}>
            <AppInput
              type="date"
              value={customRange.start_date ?? ""}
              onChange={(event) => {
                onPeriodModeChange("custom");
                onCustomRangeChange({ ...customRange, start_date: event.target.value || undefined });
              }}
              className="min-h-10 rounded-xl px-3 text-xs font-bold"
            />
          </CompactField>
          <CompactField label={periodMode === "custom" ? "Sampai" : "Sampai custom"}>
            <AppInput
              type="date"
              value={customRange.end_date ?? ""}
              onChange={(event) => {
                onPeriodModeChange("custom");
                onCustomRangeChange({ ...customRange, end_date: event.target.value || undefined });
              }}
              className="min-h-10 rounded-xl px-3 text-xs font-bold"
            />
          </CompactField>
          <p className="rounded-2xl bg-slate-50 px-4 py-3 text-xs font-semibold leading-5 text-slate-500">
            Quick periode otomatis mengirim satu mode filter saja. Date range aktif hanya saat periode Custom.
          </p>
        </div>
      ) : null}
    </div>
  );
}

function CompactField({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="grid w-full min-w-0 gap-1 text-xs font-black uppercase tracking-normal text-slate-400 sm:w-auto">
      <span>{label}</span>
      {children}
    </label>
  );
}

function ExpenseTrendChart({
  points,
  totalExpense,
  currency,
  periodLabel,
  displayAmount
}: {
  points: Array<{ date: string; label?: string; total: number }>;
  totalExpense: number;
  currency: string;
  periodLabel: string;
  displayAmount: (value: number | string) => number;
}) {
  const resolvedMode = resolveTrendMode(points);
  const trendPoints = aggregateTrend(points, resolvedMode);
  const hasExpense = trendPoints.some((point) => point.total > 0);
  const max = Math.max(...trendPoints.map((point) => Number(point.total || 0)), 1);
  const compact = resolvedMode !== "daily" || trendPoints.length > 7;
  const xLabelInterval = resolvedMode === "daily"
    ? trendPoints.length > 21 ? 5 : trendPoints.length > 7 ? 3 : 1
    : 1;
  const topValueKeys = new Set(
    trendPoints
      .filter((point) => point.total > 0)
      .sort((a, b) => b.total - a.total)
      .slice(0, compact ? 3 : trendPoints.length)
      .map((point) => point.key)
  );
  const minBarWidth = resolvedMode === "daily" && trendPoints.length > 14 ? 22 : 36;
  const chartMinWidth = Math.max(0, trendPoints.length * minBarWidth);
  const modeLabel = resolvedMode === "daily" ? "Harian" : resolvedMode === "weekly" ? "Mingguan" : "Bulanan";

  return (
    <div>
      <div className="mb-4 flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="font-black text-slate-900">Tren pengeluaran harian</h2>
            <span className="rounded-full bg-poketto-50 px-3 py-1 text-xs font-black text-poketto-700">{modeLabel}</span>
          </div>
          <p className="mt-1 text-sm font-semibold text-slate-400">
            Total periode ini: <span className="text-poketto-700">{formatCurrency(totalExpense, currency)}</span>
          </p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
          <span className="rounded-full bg-slate-50 px-3 py-1 text-xs font-bold text-slate-400">
            {periodLabel}
          </span>
        </div>
      </div>

      {!hasExpense ? (
        <div className="grid h-72 place-items-center rounded-2xl bg-slate-50 p-4">
          <EmptyState title="Belum ada pengeluaran pada periode ini." />
        </div>
      ) : (
        <div className="overflow-x-auto rounded-2xl bg-slate-50">
          <div
            className="flex h-80 items-end gap-2 p-4"
            style={{ minWidth: chartMinWidth ? `${chartMinWidth}px` : undefined }}
          >
            {trendPoints.map((item, index) => {
              const total = Number(item.total || 0);
              const isHighest = total === max && max > 0;
              const shouldShowValue = topValueKeys.has(item.key);
              const shouldShowXAxis = index % xLabelInterval === 0 || index === trendPoints.length - 1;
              const barHeight = total > 0 ? Math.max(10, (total / max) * 210) : 6;

              return (
                <div key={item.key} className="group relative flex min-w-0 flex-1 flex-col items-center gap-2">
                  <div className="pointer-events-none absolute -top-10 z-10 whitespace-nowrap rounded-lg bg-slate-900 px-2 py-1 text-xs font-bold text-white opacity-0 shadow-lg transition-opacity group-hover:opacity-100">
                    {item.tooltipLabel}: {formatCurrency(displayAmount(total), currency)}
                  </div>
                  <span className={`h-4 text-[0.65rem] font-bold ${shouldShowValue ? "text-poketto-700" : "text-transparent"}`}>
                    {shouldShowValue ? formatCurrency(displayAmount(total), currency) : "-"}
                  </span>
                  <div
                    className={`w-full rounded-t-xl transition hover:brightness-110 ${
                      isHighest ? "bg-poketto-700" : total > 0 ? "bg-poketto-500" : "bg-slate-200"
                    } ${total > 0 ? "" : "opacity-50"}`}
                    style={{ height: `${barHeight}px` }}
                    title={`${item.tooltipLabel}: ${formatCurrency(displayAmount(total), currency)}`}
                  />
                  <span className={`h-4 text-[0.65rem] font-bold ${shouldShowXAxis ? "text-slate-400" : "text-transparent"}`}>
                    {shouldShowXAxis ? item.label : "-"}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

function BudgetProgressCard({
  title,
  spent,
  budget,
  remaining,
  percentage,
  currency,
  danger
}: {
  title: string;
  spent: number;
  budget: number;
  remaining: number;
  percentage: number;
  currency: string;
  danger: boolean;
}) {
  return (
    <AppCard className={danger ? "border-red-200 bg-red-50" : "border-slate-100"}>
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className={`font-black ${danger ? "text-red-700" : "text-slate-900"}`}>{title}</h2>
          <p className="mt-1 text-sm font-semibold text-slate-400">
            {formatCurrency(spent, currency)} dari {formatCurrency(budget, currency)}
          </p>
        </div>
        {danger ? (
          <span className="rounded-full bg-red-100 px-3 py-1 text-xs font-black text-red-700">Budget habis</span>
        ) : (
          <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-black text-slate-500">{Math.round(percentage)}%</span>
        )}
      </div>
      <div className="mt-4 h-3 overflow-hidden rounded-full bg-white">
        <div
          className={`h-full rounded-full ${danger ? "bg-red-500" : percentage >= 80 ? "bg-amber-500" : "bg-poketto-500"}`}
          style={{ width: `${Math.min(100, Math.max(0, percentage))}%` }}
        />
      </div>
      <p className={`mt-3 text-sm font-bold ${danger ? "text-red-700" : "text-slate-500"}`}>
        Sisa budget: {formatCurrency(remaining, currency)}
      </p>
    </AppCard>
  );
}
