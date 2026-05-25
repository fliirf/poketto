"use client";

import { useEffect, useState } from "react";
import { AppLayout } from "@/components/layout/AppLayout";
import { PageHeader } from "@/components/layout/PageHeader";
import { TransactionForm } from "@/components/TransactionForm";
import { ErrorState, LoadingState } from "@/components/ui/States";
import { api } from "@/lib/api";
import type { Category } from "@/types/poketto";

export default function NewTransactionPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .categories()
      .then((data) => setCategories(data.categories))
      .catch((err) => setError(err instanceof Error ? err.message : "Kategori gagal dimuat."))
      .finally(() => setLoading(false));
  }, []);

  return (
    <AppLayout>
      <PageHeader title="Tambah Transaksi" description="Catat pemasukan atau pengeluaran baru." />
      {loading ? <LoadingState /> : null}
      {error ? <ErrorState message={error} /> : null}
      {!loading && !error ? <TransactionForm categories={categories} /> : null}
    </AppLayout>
  );
}
