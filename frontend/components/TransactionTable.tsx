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
  currencyRate = 1
}: {
  transactions: Transaction[];
  onDelete?: (id: number) => Promise<void> | void;
  deletingId?: number | null;
  currency?: string;
  currencyRate?: number;
}) {
  const [pendingDeleteId, setPendingDeleteId] = useState<number | null>(null);

  if (!transactions.length) {
    return <EmptyState title="Belum ada transaksi" description="Data akan muncul setelah transaksi dicatat." />;
  }

  return (
    <AppTable
      headers={["Tanggal", "Kategori", "Catatan", "Lokasi", "Nominal", "Aksi"]}
      columnClasses={["w-32", "w-40", "w-64", "w-56", "w-48", "w-44"]}
      headerClasses={["", "", "", "", "text-right", "text-right"]}
      minWidthClass="min-w-[1040px]"
    >
      {transactions.map((transaction) => {
        const type = transaction.type ?? transaction.category?.type ?? "expense";
        const category = transaction.category?.name ?? transaction.category_name ?? "Tanpa kategori";
        return (
          <tr key={transaction.id} className="rounded-2xl bg-slate-50 text-sm">
            <td className="rounded-l-2xl px-3 py-4 whitespace-nowrap text-slate-500">
              {formatDate(transaction.date ?? transaction.transaction_date)}
            </td>
            <td className="px-3 py-4">
              <div className="truncate whitespace-nowrap" title={category}>
                <Badge tone={type}>{category}</Badge>
              </div>
            </td>
            <td className="px-3 py-4 text-slate-600">
              <div className="truncate whitespace-nowrap" title={transaction.description || "-"}>
                {transaction.description || "-"}
              </div>
            </td>
            <td className="px-3 py-4 text-slate-400">
              <div className="truncate whitespace-nowrap" title={transaction.location_name || "-"}>
                {transaction.location_name || "-"}
              </div>
            </td>
            <td className={`px-3 py-4 text-right font-black whitespace-nowrap ${type === "income" ? "text-emerald-600" : "text-red-600"}`}>
              {type === "income" ? "+" : "-"} {formatCurrency(Number(transaction.amount || 0) * currencyRate, currency)}
            </td>
            <td className="rounded-r-2xl px-3 py-4">
              <div className="flex items-center justify-end gap-2">
                <Link
                  href={`/transactions/${transaction.id}/edit`}
                  className="inline-flex h-10 min-w-16 items-center justify-center rounded-xl border border-slate-200 bg-white px-4 text-xs font-extrabold text-slate-600 shadow-sm transition hover:border-poketto-200 hover:bg-poketto-50 hover:text-poketto-700"
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
