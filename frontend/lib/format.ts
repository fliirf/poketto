export function formatCurrency(value: number | string | null | undefined, currency = "IDR") {
  const amount = Number(value ?? 0);
  const fractionDigits = ["IDR", "JPY"].includes(currency.toUpperCase()) ? 0 : 2;
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency,
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits
  }).format(amount);
}

export function getStoredCurrency() {
  if (typeof window === "undefined") return "IDR";
  return window.localStorage.getItem("poketto_currency") || "IDR";
}

export function setStoredCurrency(currency: string) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem("poketto_currency", currency);
}

export function formatAppCurrency(value: number | string | null | undefined, currency = getStoredCurrency()) {
  return formatCurrency(value, currency);
}

export function formatNumberInput(value: number | string | null | undefined) {
  const rawValue = String(value ?? "").trim();
  const normalizedValue = /^-?\d+\.\d{1,2}$/.test(rawValue)
    ? String(Math.trunc(Number(rawValue)))
    : rawValue;
  const digits = normalizedValue.replace(/\D/g, "");
  if (!digits) return "";

  return new Intl.NumberFormat("id-ID").format(Number(digits));
}

export function parseNumberInput(value: string) {
  const digits = value.replace(/\D/g, "");
  return digits ? Number(digits) : 0;
}

export function formatDate(value?: string | null) {
  if (!value) return "-";
  return new Intl.DateTimeFormat("id-ID", {
    day: "2-digit",
    month: "short",
    year: "numeric"
  }).format(parseAppDate(value));
}

export function toDateInput(value?: string | null) {
  const date = value ? parseAppDate(value) : new Date();
  const offset = date.getTimezoneOffset();
  const local = new Date(date.getTime() - offset * 60_000);
  return local.toISOString().slice(0, 10);
}

function parseAppDate(value: string) {
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    const [year, month, day] = value.split("-").map(Number);
    return new Date(year, month - 1, day);
  }

  return new Date(value);
}

export function classNames(...values: Array<string | false | null | undefined>) {
  return values.filter(Boolean).join(" ");
}
