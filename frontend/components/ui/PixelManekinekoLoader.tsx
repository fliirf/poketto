export function PixelManekinekoLoader({
  title = "Menyiapkan Poketto...",
  subtitle = "Manekineko sedang merapikan dashboard kamu.",
  compact = false,
}: {
  title?: string;
  subtitle?: string;
  compact?: boolean;
}) {
  return (
    <div className={`pixel-loader ${compact ? "pixel-loader-compact" : ""}`}>
      <div className="pixel-loader-card">
        <svg viewBox="0 0 160 160" aria-hidden="true" className="pixel-cat">
          <rect x="42" y="34" width="76" height="86" rx="18" className="pixel-cat-cream" />
          <rect x="50" y="24" width="20" height="24" rx="4" className="pixel-cat-cream" />
          <rect x="90" y="24" width="20" height="24" rx="4" className="pixel-cat-cream" />
          <rect x="54" y="31" width="10" height="12" rx="2" className="pixel-cat-orange-soft" />
          <rect x="96" y="31" width="10" height="12" rx="2" className="pixel-cat-orange-soft" />
          <rect x="64" y="62" width="10" height="10" rx="2" className="pixel-cat-eye" />
          <rect x="96" y="62" width="10" height="10" rx="2" className="pixel-cat-eye" />
          <rect x="64" y="62" width="10" height="10" rx="2" className="pixel-cat-blink" />
          <rect x="96" y="62" width="10" height="10" rx="2" className="pixel-cat-blink" />
          <rect x="78" y="76" width="14" height="10" rx="3" className="pixel-cat-orange" />
          <rect x="72" y="92" width="26" height="6" rx="3" className="pixel-cat-mouth" />
          <rect x="56" y="100" width="20" height="20" rx="6" className="pixel-cat-paw" />
          <g className="pixel-cat-wave">
            <rect x="105" y="78" width="22" height="44" rx="8" className="pixel-cat-paw" />
            <rect x="110" y="86" width="5" height="8" rx="2" className="pixel-cat-line" />
            <rect x="119" y="86" width="5" height="8" rx="2" className="pixel-cat-line" />
          </g>
          <rect x="72" y="108" width="30" height="22" rx="7" className="pixel-cat-belly" />
          <rect x="79" y="114" width="16" height="5" rx="2" className="pixel-cat-orange" />
          <circle cx="38" cy="118" r="10" className="pixel-coin" />
          <rect x="35" y="113" width="6" height="10" rx="2" className="pixel-coin-line" />
          <rect x="124" y="44" width="8" height="8" className="pixel-sparkle pixel-sparkle-one" />
          <rect x="28" y="58" width="6" height="6" className="pixel-sparkle pixel-sparkle-two" />
        </svg>
      </div>
      <div className="text-center">
        <p className="font-black text-slate-900">{title}</p>
        <p className="mt-1 text-sm font-semibold text-slate-500">{subtitle}</p>
        <div className="mt-4 flex justify-center gap-1.5" aria-hidden="true">
          <span className="pixel-dot" />
          <span className="pixel-dot pixel-dot-delay-one" />
          <span className="pixel-dot pixel-dot-delay-two" />
        </div>
      </div>
    </div>
  );
}
