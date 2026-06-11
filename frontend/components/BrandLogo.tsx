import Image from "next/image";
import { classNames } from "@/lib/format";

export function BrandLogo({
  compact = false,
  className = ""
}: {
  compact?: boolean;
  className?: string;
}) {
  return (
    <div className={classNames("flex items-center gap-3", className)}>
      <span className="grid h-12 w-12 place-items-center rounded-2xl bg-poketto-50 shadow-sm ring-1 ring-poketto-100">
        <Image
          src="/poketto-mobile-logo.png"
          alt=""
          width={40}
          height={40}
          className="h-9 w-9 object-contain"
          priority
        />
      </span>
      {!compact ? (
        <span className="block">
          <span className="font-brand block text-xl font-black tracking-normal text-poketto-600">POKETTO</span>
          <span className="mt-1 block text-xs font-semibold text-slate-400">Finance dashboard</span>
        </span>
      ) : null}
    </div>
  );
}
