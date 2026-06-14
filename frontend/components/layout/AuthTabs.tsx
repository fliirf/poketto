export type AuthMode = "login" | "register";

const tabs: Array<{ label: string; mode: AuthMode }> = [
  { label: "Masuk", mode: "login" },
  { label: "Daftar", mode: "register" },
];

export function AuthTabs({
  active,
  onChange
}: {
  active: AuthMode;
  onChange: (mode: AuthMode) => void;
}) {
  const activeIndex = tabs.findIndex((tab) => tab.mode === active);

  return (
    <div className="relative grid grid-cols-2 rounded-2xl bg-slate-100/80 p-1 text-sm font-black text-slate-500">
      <span
        aria-hidden="true"
        className="auth-tab-indicator absolute bottom-1 left-1 top-1 w-[calc(50%-4px)] rounded-xl bg-white shadow-sm"
        style={{ transform: `translateX(${activeIndex * 100}%)` }}
      />
      {tabs.map((tab) => (
        <button
          key={tab.mode}
          type="button"
          aria-current={active === tab.mode ? "page" : undefined}
          onClick={() => onChange(tab.mode)}
          className={`relative z-10 rounded-xl px-4 py-3 text-center transition-colors ${
            active === tab.mode ? "text-poketto-700" : "text-slate-500 hover:text-slate-800"
          }`}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}
