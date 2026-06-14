import { classNames } from "@/lib/format";

export function AppCard({
  children,
  className = ""
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <section className={classNames("min-w-0 rounded-[1.35rem] border border-white/80 bg-white/95 p-4 shadow-soft backdrop-blur sm:p-5", className)}>
      {children}
    </section>
  );
}
