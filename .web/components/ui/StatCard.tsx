import { classNames, formatCurrency } from "@/lib/format";
import { AppCard } from "@/components/ui/AppCard";

export function StatCard({
  label,
  value,
  tone = "neutral",
  helper
}: {
  label: string;
  value: number | string;
  tone?: "neutral" | "income" | "expense" | "warning";
  helper?: string;
}) {
  const tones = {
    neutral: "text-slate-950",
    income: "text-emerald-600",
    expense: "text-red-600",
    warning: "text-amber-600"
  };

  return (
    <AppCard className="min-h-36">
      <p className="text-sm font-bold text-slate-500">{label}</p>
      <p className={classNames("mt-3 text-2xl font-black tracking-normal sm:text-3xl", tones[tone])}>
        {typeof value === "number" ? formatCurrency(value) : value}
      </p>
      {helper ? <p className="mt-3 text-sm text-slate-500">{helper}</p> : null}
    </AppCard>
  );
}
