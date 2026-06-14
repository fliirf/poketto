"use client";

import Link from "next/link";
import { useState } from "react";
import { AppButton } from "@/components/ui/AppButton";
import { AppTable } from "@/components/ui/AppTable";
import { Badge } from "@/components/ui/Badge";
import { EmptyState } from "@/components/ui/States";
import { formatCurrency, formatDate } from "@/lib/format";
import type { Transaction } from "@/types/poketto";

export function TransactionTable({
  transactions,
  onDelete,
  deletingId,
  currency = "IDR",
  currencyRate = 1,
  compact = false
}: {
  transactions: Transaction[];
  onDelete?: (id: number) => Promise<void> | void;
  deletingId?: number | null;
  currency?: string;
  currencyRate?: number;
  compact?: boolean;
}) {
  const [pendingDeleteId, setPendingDeleteId] = useState<number | null>(null);

  if (!transactions.length) {
    return <EmptyState title="Belum ada transaksi" description="Data akan muncul setelah transaksi dicatat." />;
  }

  return (
    <AppTable
      headers={["Tanggal", "Kategori", "Catatan", "Lokasi", "Nominal", "Aksi"]}
      columnClasses={compact ? ["w-28", "w-36", "w-52", "w-44", "w-40", "w-24"] : ["w-32", "w-40", "w-64", "w-56", "w-48", "w-44"]}
      headerClasses={["", "", "", "", "text-right", "text-right"]}
      minWidthClass={compact ? "min-w-[820px]" : "min-w-[1040px]"}
    >
      {transactions.map((transaction) => {
        const type = transaction.type ?? transaction.category?.type ?? "expense";
        const category = transaction.category?.name ?? transaction.category_name ?? "Tanpa kategori";
        const location = formatLocationLabel(transaction.location_name);
        return (
          <tr key={transaction.id} className="rounded-2xl bg-slate-50 text-sm">
            <td className={`rounded-l-2xl px-3 ${compact ? "py-3" : "py-4"} whitespace-nowrap text-slate-500`}>
              {formatDate(transaction.date ?? transaction.transaction_date)}
            </td>
            <td className={`px-3 ${compact ? "py-3" : "py-4"}`}>
              <div className="truncate whitespace-nowrap" title={category}>
                <Badge tone={type}>{category}</Badge>
              </div>
            </td>
            <td className={`px-3 ${compact ? "py-3" : "py-4"} text-slate-600`}>
              <div className="truncate whitespace-nowrap" title={transaction.description || "-"}>
                {transaction.description || "-"}
              </div>
            </td>
            <td className={`px-3 ${compact ? "py-3" : "py-4"} text-slate-400`}>
              <div className="truncate whitespace-nowrap" title={transaction.location_name || "-"}>
                {location}
              </div>
            </td>
            <td className={`px-3 ${compact ? "py-3" : "py-4"} text-right font-black whitespace-nowrap ${type === "income" ? "text-emerald-600" : "text-red-600"}`}>
              {type === "income" ? "+" : "-"} {formatCurrency(Number(transaction.amount || 0) * currencyRate, currency)}
            </td>
            <td className={`rounded-r-2xl px-3 ${compact ? "py-3" : "py-4"}`}>
              <div className="flex items-center justify-end gap-2">
                <Link
                  href={`/transactions/${transaction.id}/edit`}
                  className={`${compact ? "h-9 min-w-14 px-3" : "h-10 min-w-16 px-4"} inline-flex items-center justify-center rounded-xl border border-slate-200 bg-white text-xs font-extrabold text-slate-600 shadow-sm transition hover:border-poketto-200 hover:bg-poketto-50 hover:text-poketto-700`}
                >
                  Edit
                </Link>
                {onDelete ? (
                  pendingDeleteId === transaction.id ? (
                    <>
                      <AppButton
                        type="button"
                        variant="danger"
                        className="h-10 min-h-0 min-w-24 rounded-xl px-4 text-xs"
                        disabled={deletingId === transaction.id}
                        onClick={() => {
                          onDelete(transaction.id);
                          setPendingDeleteId(null);
                        }}
                      >
                        {deletingId === transaction.id ? "Menghapus..." : "Konfirmasi"}
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
                      onClick={() => setPendingDeleteId(transaction.id)}
                    >
                      Hapus
                    </AppButton>
                  )
                ) : null}
              </div>
            </td>
          </tr>
        );
      })}
    </AppTable>
  );
}

function formatLocationLabel(value?: string | null) {
  const raw = String(value ?? "").trim();
  if (!raw) return "-";

  const parts = raw
    .split(",")
    .map((part) => cleanLocationPart(part))
    .filter(Boolean);
  if (!parts.length) return raw.length > 42 ? `${raw.slice(0, 39)}...` : raw;

  const district = findLocationPart(parts, [
    "kec.",
    "kecamatan",
    "district",
    "subdistrict",
    "dayeuhkolot",
    "bojongsoang",
    "coblong"
  ]) ?? parts[0];
  const city = findLocationPart(parts, ["kota", "city"]);
  const regency = findLocationPart(parts, ["kab.", "kabupaten", "regency"]);
  const fallbackArea = parts.find((part) => !sameLocation(part, district) && !/indonesia|jawa|west java|provinsi|province/i.test(part));

  if (city) return joinLocation(district, formatCity(city));
  if (regency) return joinLocation(district, formatRegency(regency));

  if (fallbackArea) {
    const normalized = /bandung/i.test(fallbackArea) && !/kota|kab/i.test(fallbackArea)
      ? `Kab. ${fallbackArea}`
      : fallbackArea;
    return joinLocation(district, normalized);
  }

  return parts.slice(0, 2).join(", ");
}

function cleanLocationPart(value: string) {
  return value
    .replace(/\s+/g, " ")
    .trim();
}

function findLocationPart(parts: string[], keywords: string[]) {
  return parts.find((part) => {
    const lower = part.toLowerCase();
    return keywords.some((keyword) => lower.includes(keyword.toLowerCase()));
  });
}

function sameLocation(left?: string, right?: string) {
  return cleanLocationPart(left ?? "").toLowerCase() === cleanLocationPart(right ?? "").toLowerCase();
}

function formatCity(value: string) {
  const cleaned = cleanLocationPart(value).replace(/^kota\s+/i, "").replace(/\bcity\b/i, "").trim();
  return `Kota ${cleaned}`;
}

function formatRegency(value: string) {
  const cleaned = cleanLocationPart(value).replace(/^kab\.?\s+/i, "").replace(/^kabupaten\s+/i, "").replace(/\bregency\b/i, "").trim();
  return `Kab. ${cleaned}`;
}

function joinLocation(district?: string, area?: string) {
  const first = cleanLocationPart(district ?? "").replace(/^kecamatan\s+/i, "").replace(/\bdistrict\b/i, "").trim();
  const second = cleanLocationPart(area ?? "");
  if (!first) return second || "-";
  if (!second || sameLocation(first, second)) return first;
  return `${first}, ${second}`;
}
