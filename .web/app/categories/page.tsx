"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { AppLayout } from "@/components/layout/AppLayout";
import { PageHeader } from "@/components/layout/PageHeader";
import { CategoryForm } from "@/components/CategoryForm";
import { AppButton } from "@/components/ui/AppButton";
import { AppCard } from "@/components/ui/AppCard";
import { Badge } from "@/components/ui/Badge";
import { EmptyState, ErrorState, LoadingState } from "@/components/ui/States";
import { useToast } from "@/components/ui/ToastProvider";
import { api } from "@/lib/api";
import { formatCurrency } from "@/lib/format";
import type { Category } from "@/types/poketto";

export default function CategoriesPage() {
  const toast = useToast();
  const [categories, setCategories] = useState<Category[]>([]);
  const [pendingDeleteId, setPendingDeleteId] = useState<number | null>(null);
  const [deletingId, setDeletingId] = useState<number | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  const loadCategories = useCallback(async () => {
    setError("");
    setLoading(true);
    try {
      const data = await api.categories();
      setCategories(data.categories);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Kategori gagal dimuat.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadCategories();
  }, [loadCategories]);

  async function deleteCategory(id: number) {
    if (deletingId) return;
    setDeletingId(id);
    setError("");
    try {
      await api.deleteCategory(id);
      setCategories((current) => current.filter((category) => category.id !== id));
      toast.success("Kategori berhasil dihapus.");
    } catch (err) {
      const message = err instanceof Error ? err.message : "Kategori gagal dihapus.";
      setError(message);
      toast.error(message);
    } finally {
      setDeletingId(null);
    }
  }

  return (
    <AppLayout>
      <PageHeader title="Kategori & Budget" description="Kelola kategori pemasukan, pengeluaran, dan budget bulanan." />
      <div className="grid gap-5 lg:grid-cols-[0.8fr_1.2fr]">
        <CategoryForm onSaved={loadCategories} />
        <AppCard>
          {loading ? <LoadingState /> : null}
          {error ? <ErrorState message={error} /> : null}
          {!loading && !categories.length ? <EmptyState title="Belum ada kategori" /> : null}
          <div className="grid gap-3">
            {categories.map((category) => (
              <div key={category.id} className="flex flex-col gap-3 rounded-2xl bg-slate-50 p-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <div className="flex flex-wrap items-center gap-2">
                    <p className="font-black text-slate-900">{category.name}</p>
                    <Badge tone={category.type}>{category.type === "income" ? "Pemasukan" : "Pengeluaran"}</Badge>
                  </div>
                  <p className="mt-1 text-sm text-slate-500">Budget: {formatCurrency(category.monthly_budget ?? 0)}</p>
                </div>
                <div className="flex gap-2">
                  <Link
                    href={`/categories/${category.id}/edit`}
                    className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-bold text-slate-600 transition hover:text-poketto-700"
                  >
                    Edit
                  </Link>
                  {pendingDeleteId === category.id ? (
                    <>
                      <AppButton
                        type="button"
                        variant="danger"
                        className="min-h-0 rounded-xl px-3 py-2 text-xs"
                        disabled={deletingId === category.id}
                        onClick={() => {
                          deleteCategory(category.id);
                          setPendingDeleteId(null);
                        }}
                      >
                        {deletingId === category.id ? "Menghapus..." : "Konfirmasi"}
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
                      disabled={Boolean(deletingId)}
                      onClick={() => setPendingDeleteId(category.id)}
                    >
                      Hapus
                    </AppButton>
                  )}
                </div>
              </div>
            ))}
          </div>
        </AppCard>
      </div>
    </AppLayout>
  );
}
