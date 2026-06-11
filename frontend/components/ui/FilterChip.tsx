import { classNames } from "@/lib/format";

export function FilterChip({
  active,
  children,
  onClick
}: {
  active?: boolean;
  children: React.ReactNode;
  onClick?: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={classNames(
        "rounded-full border px-4 py-2 text-sm font-semibold transition",
        active ? "border-poketto-500 bg-poketto-50 text-poketto-700" : "border-slate-200 bg-white text-slate-600"
      )}
    >
      {children}
    </button>
  );
}
