"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { AppLayout } from "@/components/layout/AppLayout";
import { PageHeader } from "@/components/layout/PageHeader";
import { CategoryForm } from "@/components/CategoryForm";
import { ErrorState, LoadingState } from "@/components/ui/States";
import { api } from "@/lib/api";
import type { Category } from "@/types/poketto";

export default function EditCategoryPage() {
  const params = useParams<{ id: string }>();
  const [category, setCategory] = useState<Category | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .category(params.id)
      .then((data) => setCategory(data.category))
      .catch((err) => setError(err instanceof Error ? err.message : "Kategori gagal dimuat."))
      .finally(() => setLoading(false));
  }, [params.id]);

  return (
    <AppLayout>
      <PageHeader title="Edit Kategori" description="Perbarui nama, tipe, dan budget kategori." />
      {loading ? <LoadingState /> : null}
      {error ? <ErrorState message={error} /> : null}
      {!loading && category ? (
        <div className="mx-auto max-w-2xl">
          <CategoryForm category={category} />
        </div>
      ) : null}
    </AppLayout>
  );
}
