"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { AppLayout } from "@/components/layout/AppLayout";
import { PageHeader } from "@/components/layout/PageHeader";
import { TransactionForm } from "@/components/TransactionForm";
import { ErrorState, LoadingState } from "@/components/ui/States";
import { api } from "@/lib/api";
import type { Category, Transaction } from "@/types/poketto";

export default function EditTransactionPage() {
  const params = useParams<{ id: string }>();
  const [transaction, setTransaction] = useState<Transaction | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    Promise.all([api.transaction(params.id), api.categories()])
      .then(([transactionData, categoryData]) => {
        setTransaction(transactionData.transaction);
        setCategories(categoryData.categories);
      })
      .catch((err) => setError(err instanceof Error ? err.message : "Transaksi gagal dimuat."))
      .finally(() => setLoading(false));
  }, [params.id]);

  return (
    <AppLayout>
      <PageHeader title="Edit Transaksi" description="Perbarui data transaksi tanpa mengubah payload API." />
      {loading ? <LoadingState /> : null}
      {error ? <ErrorState message={error} /> : null}
      {!loading && transaction ? <TransactionForm categories={categories} transaction={transaction} /> : null}
    </AppLayout>
  );
}
