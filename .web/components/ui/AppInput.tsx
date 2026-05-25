import { InputHTMLAttributes, TextareaHTMLAttributes } from "react";
import { classNames } from "@/lib/format";

export function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="grid gap-2 text-sm font-semibold text-slate-700">
      <span>{label}</span>
      {children}
    </label>
  );
}

export function AppInput({ className, ...props }: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={classNames(
        "min-h-11 rounded-2xl border border-slate-200 bg-white px-4 text-sm font-medium outline-none transition placeholder:text-slate-400 focus:border-poketto-500 focus:ring-4 focus:ring-poketto-100",
        className
      )}
      {...props}
    />
  );
}

export function AppTextarea({ className, ...props }: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      className={classNames(
        "rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium outline-none transition placeholder:text-slate-400 focus:border-poketto-500 focus:ring-4 focus:ring-poketto-100",
        className
      )}
      {...props}
    />
  );
}
