export function formatCurrency(value: number | string | null | undefined, currency = "IDR") {
  const amount = Number(value ?? 0);
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency,
    maximumFractionDigits: 0
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
  const normalizedValue = /^-?\d+(\.\d+)?$/.test(rawValue)
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
  }).format(new Date(value));
}

export function toDateInput(value?: string | null) {
  const date = value ? new Date(value) : new Date();
  const offset = date.getTimezoneOffset();
  const local = new Date(date.getTime() - offset * 60_000);
  return local.toISOString().slice(0, 10);
}

export function classNames(...values: Array<string | false | null | undefined>) {
  return values.filter(Boolean).join(" ");
}
