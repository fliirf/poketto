"use client";

import { AppButton } from "@/components/ui/AppButton";
import { AppInput, Field } from "@/components/ui/AppInput";
import { AppSelect } from "@/components/ui/AppSelect";
import type { Category, Filters } from "@/types/poketto";

export function FilterPanel({
  filters,
  categories,
  onChange,
  onReset
}: {
  filters: Filters;
  categories: Category[];
  onChange: (filters: Filters) => void;
  onReset: () => void;
}) {
  return (
    <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-[1fr_1fr_1fr_1.15fr_1fr_auto] xl:items-end">
      <Field label="Mulai">
        <AppInput type="date" value={filters.start_date ?? ""} onChange={(event) => onChange({ ...filters, start_date: event.target.value })} />
      </Field>
      <Field label="Sampai">
        <AppInput type="date" value={filters.end_date ?? ""} onChange={(event) => onChange({ ...filters, end_date: event.target.value })} />
      </Field>
      <Field label="Bulan">
        <AppInput type="month" value={filters.month ?? ""} onChange={(event) => onChange({ ...filters, month: event.target.value })} />
      </Field>
      <Field label="Kategori">
        <AppSelect value={filters.category_id ?? ""} onChange={(event) => onChange({ ...filters, category_id: event.target.value })}>
          <option value="">Semua</option>
          {categories.map((category) => (
            <option key={category.id} value={category.id}>
              {category.name}
            </option>
          ))}
        </AppSelect>
      </Field>
      <Field label="Tipe">
        <AppSelect value={filters.type ?? ""} onChange={(event) => onChange({ ...filters, type: event.target.value as Filters["type"] })}>
          <option value="">Semua</option>
          <option value="income">Pemasukan</option>
          <option value="expense">Pengeluaran</option>
        </AppSelect>
      </Field>
      <div className="flex md:col-span-2 xl:col-span-1">
        <AppButton type="button" variant="secondary" className="w-full xl:min-w-28" onClick={onReset}>
          Reset
        </AppButton>
      </div>
    </div>
  );
}
