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
  onDelete
}: {
  transactions: Transaction[];
  onDelete?: (id: number) => void;
}) {
  const [pendingDeleteId, setPendingDeleteId] = useState<number | null>(null);

  if (!transactions.length) {
    return <EmptyState title="Belum ada transaksi" description="Data akan muncul setelah transaksi dicatat." />;
  }

  return (
    <AppTable headers={["Tanggal", "Kategori", "Catatan", "Lokasi", "Nominal", "Aksi"]}>
      {transactions.map((transaction) => {
        const type = transaction.type ?? transaction.category?.type ?? "expense";
        const category = transaction.category?.name ?? transaction.category_name ?? "Tanpa kategori";
        return (
          <tr key={transaction.id} className="rounded-2xl bg-slate-50 text-sm">
            <td className="rounded-l-2xl px-3 py-4 text-slate-500">{formatDate(transaction.date ?? transaction.transaction_date)}</td>
            <td className="px-3 py-4">
              <Badge tone={type}>{category}</Badge>
            </td>
            <td className="max-w-[14rem] truncate px-3 py-4 text-slate-600">{transaction.description || "-"}</td>
            <td className="max-w-[12rem] truncate px-3 py-4 text-slate-400">
              {transaction.location_name || "-"}
            </td>
            <td className={`px-3 py-4 text-right font-black ${type === "income" ? "text-emerald-600" : "text-red-600"}`}>
              {type === "income" ? "+" : "-"} {formatCurrency(transaction.amount)}
            </td>
            <td className="rounded-r-2xl px-3 py-4">
              <div className="flex justify-end gap-2">
                <Link
                  href={`/transactions/${transaction.id}/edit`}
                  className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-bold text-slate-600 transition hover:text-poketto-700"
                >
                  Edit
                </Link>
                {onDelete ? (
                  pendingDeleteId === transaction.id ? (
                    <>
                      <AppButton
                        type="button"
                        variant="danger"
                        className="min-h-0 rounded-xl px-3 py-2 text-xs"
                        onClick={() => {
                          onDelete(transaction.id);
                          setPendingDeleteId(null);
                        }}
                      >
                        Konfirmasi
                      </AppButton>
                      <AppButton
                        type="button"
                        variant="ghost"
                        className="min-h-0 rounded-xl px-3 py-2 text-xs"
                        onClick={() => setPendingDeleteId(null)}
                      >
                        Batal
                      </AppButton>
                    </>
                  ) : (
                    <AppButton
                      type="button"
                      variant="danger"
                      className="min-h-0 rounded-xl px-3 py-2 text-xs"
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
