import type { ExchangeRate } from "@/types/poketto";

const BASE_CURRENCY = "IDR";

export function resolveDisplayCurrency(
  preferredCurrency: string | null | undefined,
  rates: ExchangeRate[]
) {
  const currency = (preferredCurrency || BASE_CURRENCY).toUpperCase();
  if (currency === BASE_CURRENCY) {
    return { currency: BASE_CURRENCY, rate: 1, converted: true };
  }

  const rate = Number(
    rates.find((item) => item.base_currency === BASE_CURRENCY && item.target_currency === currency)?.rate ?? 0
  );

  if (!Number.isFinite(rate) || rate <= 0) {
    return { currency: BASE_CURRENCY, rate: 1, converted: false };
  }

  return { currency, rate, converted: true };
}
