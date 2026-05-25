import { classNames } from "@/lib/format";

export function AppCard({
  children,
  className = ""
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <section className={classNames("rounded-[1.35rem] border border-white/80 bg-white/95 p-5 shadow-soft backdrop-blur", className)}>
      {children}
    </section>
  );
}
