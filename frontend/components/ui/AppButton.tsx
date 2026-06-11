import Link from "next/link";
import { ButtonHTMLAttributes } from "react";
import { classNames } from "@/lib/format";

type Variant = "primary" | "secondary" | "danger" | "ghost";

const variants: Record<Variant, string> = {
  primary: "bg-poketto-500 text-white shadow-sm shadow-poketto-500/25 hover:bg-poketto-600",
  secondary: "border border-slate-200 bg-white text-slate-700 hover:border-poketto-200 hover:text-poketto-700",
  danger: "bg-red-50 text-red-700 hover:bg-red-100",
  ghost: "text-slate-600 hover:bg-slate-100"
};

export function AppButton({
  className,
  variant = "primary",
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant }) {
  return (
    <button
      className={classNames(
        "inline-flex min-h-11 items-center justify-center rounded-2xl px-4 py-2 text-sm font-bold transition disabled:cursor-not-allowed disabled:opacity-60",
        variants[variant],
        className
      )}
      {...props}
    />
  );
}

export function AppLinkButton({
  href,
  children,
  className,
  variant = "primary"
}: {
  href: string;
  children: React.ReactNode;
  className?: string;
  variant?: Variant;
}) {
  return (
    <Link
      href={href}
      className={classNames(
        "inline-flex min-h-11 items-center justify-center rounded-2xl px-4 py-2 text-sm font-bold transition",
        variants[variant],
        className
      )}
    >
      {children}
    </Link>
  );
}
