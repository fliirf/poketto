import { AppCard } from "@/components/ui/AppCard";
import { PixelManekinekoLoader } from "@/components/ui/PixelManekinekoLoader";

export function LoadingState({ label = "Memuat data..." }: { label?: string }) {
  return (
    <AppCard className="border-white/80 bg-white/80">
      <PixelManekinekoLoader
        compact
        title={label}
        subtitle="Menyiapkan catatan keuanganmu..."
      />
    </AppCard>
  );
}

export function ErrorState({ message }: { message: string }) {
  return (
    <AppCard className="border-red-100 bg-red-50/90 text-red-700">
      <p className="font-bold">Ada yang belum berhasil.</p>
      <p className="mt-1 text-sm">{message}</p>
    </AppCard>
  );
}

export function EmptyState({ title, description }: { title: string; description?: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-5 py-10 text-center">
      <p className="font-bold text-slate-700">{title}</p>
      {description ? <p className="mt-1 text-sm text-slate-500">{description}</p> : null}
    </div>
  );
}
