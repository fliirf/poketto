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
import { ErrorState, LoadingState } from "@/components/ui/States";
import { useToast } from "@/components/ui/ToastProvider";
import { api } from "@/lib/api";
import { resolveDisplayCurrency } from "@/lib/currency";
import { setStoredCurrency } from "@/lib/format";
import type { Category, Filters, Transaction } from "@/types/poketto";

type TransactionPeriodMode = "all" | "today" | "week" | "month" | "year" | "custom";

const defaultPeriodMode: TransactionPeriodMode = "all";

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

function periodFilters(mode: TransactionPeriodMode, customRange: { start_date?: string; end_date?: string }): Filters {
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

  if (mode === "month") {
    return { month: currentMonthParam() };
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

  return {};
}

function buildTransactionFilters(
  mode: TransactionPeriodMode,
  customRange: { start_date?: string; end_date?: string },
  extra: Pick<Filters, "category_id" | "type">
): Filters {
  return {
    ...periodFilters(mode, customRange),
    category_id: extra.category_id || undefined,
    type: extra.type || undefined
  };
}

export default function TransactionsPage() {
  const toast = useToast();
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [periodMode, setPeriodMode] = useState<TransactionPeriodMode>(defaultPeriodMode);
  const [customRange, setCustomRange] = useState<{ start_date?: string; end_date?: string }>({});
  const [filterOptions, setFilterOptions] = useState<Pick<Filters, "category_id" | "type">>({});
  const [advancedOpen, setAdvancedOpen] = useState(false);
  const filters = useMemo(
    () => buildTransactionFilters(periodMode, customRange, filterOptions),
    [customRange, filterOptions, periodMode]
  );
  const [search, setSearch] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [deletingId, setDeletingId] = useState<number | null>(null);
  const [currency, setCurrency] = useState("IDR");
  const [currencyRate, setCurrencyRate] = useState(1);

  function resetFilters() {
    setPeriodMode(defaultPeriodMode);
    setCustomRange({});
    setFilterOptions({});
    setSearch("");
    setAdvancedOpen(false);
  }

  useEffect(() => {
    setLoading(true);
    setError("");
    Promise.all([api.transactions(filters), api.categories(), api.userSettings(), api.exchangeRates("IDR")])
      .then(([transactionData, categoryData, settingsData, exchangeRateData]) => {
        const displayCurrency = resolveDisplayCurrency(settingsData.user_settings.currency, exchangeRateData.exchange_rates);

        setTransactions(transactionData.transactions);
        setCategories(categoryData.categories);
        setCurrency(displayCurrency.currency);
        setCurrencyRate(displayCurrency.rate);
        setStoredCurrency(displayCurrency.currency);
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
  const displayAmount = (value: number) => value * currencyRate;
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
        <TransactionQuickFilter
          periodMode={periodMode}
          customRange={customRange}
          filterOptions={filterOptions}
          categories={categories}
          search={search}
          advancedOpen={advancedOpen}
          pdfPeriodLabel={pdfPeriodLabel}
          onSearchChange={setSearch}
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

        <div className="grid gap-4 md:grid-cols-3">
          <StatCard label="Pemasukan" value={displayAmount(income)} currency={currency} tone="income" />
          <StatCard label="Pengeluaran" value={displayAmount(expense)} currency={currency} tone="expense" />
          <StatCard label="Sisa" value={displayAmount(income - expense)} currency={currency} />
        </div>

        {loading ? <LoadingState /> : null}
        {error ? <ErrorState message={error} /> : null}

        {!loading ? (
          <AppCard>
            <TransactionTable transactions={filtered} onDelete={deleteTransaction} deletingId={deletingId} currency={currency} currencyRate={currencyRate} />
          </AppCard>
        ) : null}
      </div>
    </AppLayout>
  );
}

function TransactionQuickFilter({
  periodMode,
  customRange,
  filterOptions,
  categories,
  search,
  advancedOpen,
  pdfPeriodLabel,
  onSearchChange,
  onPeriodModeChange,
  onCustomRangeChange,
  onFilterOptionsChange,
  onAdvancedToggle,
  onReset
}: {
  periodMode: TransactionPeriodMode;
  customRange: { start_date?: string; end_date?: string };
  filterOptions: Pick<Filters, "category_id" | "type">;
  categories: Category[];
  search: string;
  advancedOpen: boolean;
  pdfPeriodLabel: string;
  onSearchChange: (value: string) => void;
  onPeriodModeChange: (mode: TransactionPeriodMode) => void;
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
      <div className="flex flex-col gap-2 rounded-3xl border border-white/80 bg-white/80 p-3 shadow-sm xl:flex-row xl:flex-wrap xl:items-end">
        <CompactField label="Cari">
          <AppInput
            type="search"
            placeholder="Kategori, catatan, lokasi..."
            value={search}
            onChange={(event) => onSearchChange(event.target.value)}
            className="min-h-10 w-full min-w-0 rounded-xl px-3 text-xs font-bold xl:w-64"
          />
        </CompactField>

        <CompactField label="Periode">
          <AppSelect
            value={periodMode}
            onChange={(event) => onPeriodModeChange(event.target.value as TransactionPeriodMode)}
            className="min-h-10 w-full min-w-0 rounded-xl px-3 text-xs font-bold xl:w-40"
          >
            <option value="all">Semua periode</option>
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
            className="min-h-10 w-full min-w-0 rounded-xl px-3 text-xs font-bold xl:w-44"
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
            className="min-h-10 w-full min-w-0 rounded-xl px-3 text-xs font-bold xl:w-36"
          >
            <option value="">Semua</option>
            <option value="income">Pemasukan</option>
            <option value="expense">Pengeluaran</option>
          </AppSelect>
        </CompactField>

        <div className="grid grid-cols-2 gap-2 xl:ml-auto xl:flex xl:items-end">
          <AppButton type="button" variant="secondary" className="min-h-10 rounded-xl px-3 text-xs" onClick={onAdvancedToggle}>
            Filter lanjutan
          </AppButton>
          <AppButton type="button" variant="ghost" className="min-h-10 rounded-xl px-3 text-xs" onClick={onReset}>
            Reset
          </AppButton>
        </div>
      </div>

      {advancedOpen ? (
        <div className="grid gap-3 rounded-3xl border border-slate-100 bg-white p-4 shadow-sm lg:grid-cols-[1fr_1fr_auto] lg:items-end">
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
          <p className="rounded-2xl bg-poketto-50 px-4 py-3 text-xs font-bold leading-5 text-poketto-700">
            Export PDF mengikuti filter aktif: {pdfPeriodLabel}
          </p>
        </div>
      ) : (
        <div className="rounded-2xl bg-poketto-50 px-4 py-3 text-xs font-bold text-poketto-700">
          Export PDF: {pdfPeriodLabel}
        </div>
      )}
    </div>
  );
}

function CompactField({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="grid w-full min-w-0 gap-1 text-xs font-black uppercase tracking-normal text-slate-400 xl:w-auto">
      <span>{label}</span>
      {children}
    </label>
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
