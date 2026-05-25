import { SelectHTMLAttributes } from "react";
import { classNames } from "@/lib/format";

export function AppSelect({ className, ...props }: SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select
      className={classNames(
        "min-h-11 rounded-2xl border border-slate-200 bg-white px-4 text-sm font-medium outline-none transition focus:border-poketto-500 focus:ring-4 focus:ring-poketto-100",
        className
      )}
      {...props}
    />
  );
}
