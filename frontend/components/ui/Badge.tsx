import { classNames } from "@/lib/format";
import type { TransactionType } from "@/types/poketto";

export function Badge({
  children,
  tone = "neutral"
}: {
  children: React.ReactNode;
  tone?: "neutral" | "success" | "danger" | "warning" | TransactionType;
}) {
  const styles = {
    neutral: "bg-slate-100 text-slate-700",
    success: "bg-emerald-50 text-emerald-700",
    income: "bg-emerald-50 text-emerald-700",
    danger: "bg-red-50 text-red-700",
    expense: "bg-red-50 text-red-700",
    warning: "bg-amber-50 text-amber-700"
  };
  return (
    <span className={classNames("inline-flex rounded-full px-3 py-1 text-xs font-bold", styles[tone])}>
      {children}
    </span>
  );
}
