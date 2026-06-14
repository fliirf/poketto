import Link from "next/link";

type AuthMode = "login" | "register";

const tabs: Array<{ href: string; label: string; mode: AuthMode }> = [
  { href: "/login", label: "Masuk", mode: "login" },
  { href: "/register", label: "Daftar", mode: "register" },
];

export function AuthTabs({ active }: { active: AuthMode }) {
  const activeIndex = tabs.findIndex((tab) => tab.mode === active);

  return (
    <div className="relative grid grid-cols-2 rounded-2xl bg-slate-100/80 p-1 text-sm font-black text-slate-500">
      <span
        aria-hidden="true"
        className="absolute bottom-1 left-1 top-1 w-[calc(50%-0.25rem)] rounded-xl bg-white shadow-sm transition-transform duration-300 ease-out motion-reduce:transition-none"
        style={{ transform: `translateX(${activeIndex * 100}%)` }}
      />
      {tabs.map((tab) => (
        <Link
          key={tab.mode}
          href={tab.href}
          aria-current={active === tab.mode ? "page" : undefined}
          className={`relative z-10 rounded-xl px-4 py-3 text-center transition-colors ${
            active === tab.mode ? "text-poketto-700" : "text-slate-500 hover:text-slate-800"
          }`}
        >
          {tab.label}
        </Link>
      ))}
    </div>
  );
}
