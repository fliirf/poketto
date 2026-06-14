import type {
  Category,
  BudgetNotification,
  DashboardSummary,
  ExchangeRate,
  Filters,
  Transaction,
  TransactionType,
  User,
  UserSettings
} from "@/types/poketto";

type ApiEnvelope<T> = {
  success: boolean;
  message: string;
  data: T;
  errors?: Record<string, string[]>;
};

export type TransactionPayload = {
  type: TransactionType;
  category_id: number | null;
  amount: number;
  transaction_date: string;
  description?: string | null;
  location_lat?: number | null;
  location_lng?: number | null;
  location_name?: string | null;
};

export type CategoryPayload = {
  name: string;
  type: TransactionType;
  monthly_budget: number;
};

const TOKEN_KEY = "poketto_api_token";

export function getApiBaseUrl() {
  return process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000/api";
}

export function getToken() {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string) {
  window.localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken() {
  window.localStorage.removeItem(TOKEN_KEY);
}

function buildQuery(params?: Record<string, string | number | undefined | null>) {
  const search = new URLSearchParams();
  Object.entries(params ?? {}).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== "") {
      search.set(key, String(value));
    }
  });
  const query = search.toString();
  return query ? `?${query}` : "";
}

async function request<T>(path: string, options: RequestInit = {}) {
  const token = getToken();
  const response = await fetch(`${getApiBaseUrl()}${path}`, {
    ...options,
    cache: "no-store",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers
    }
  });

  const body = (await response.json().catch(() => null)) as ApiEnvelope<T> | null;
  if (!response.ok || !body?.success) {
    const validation = body?.errors
      ? Object.values(body.errors).flat().join(" ")
      : undefined;
    throw new Error(cleanApiMessage(validation || body?.message || "Request gagal."));
  }

  return body.data;
}

async function download(path: string) {
  const token = getToken();
  const response = await fetch(`${getApiBaseUrl()}${path}`, {
    cache: "no-store",
    headers: {
      Accept: "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    }
  });

  if (!response.ok) {
    const fallback = await response.text().catch(() => "");
    let message = "";
    try {
      const json = JSON.parse(fallback) as { message?: string };
      message = json.message ?? "";
    } catch {
      message = "";
    }
    throw new Error(message || fallback || "Download PDF gagal.");
  }

  return {
    blob: await response.blob(),
    filename: filenameFromDisposition(response.headers.get("content-disposition")) ?? "Laporan_Poketto.pdf"
  };
}

function filenameFromDisposition(disposition: string | null) {
  if (!disposition) return null;
  const match = disposition.match(/filename\*=UTF-8''([^;]+)|filename="?([^";]+)"?/i);
  const value = match?.[1] ?? match?.[2];
  return value ? decodeURIComponent(value) : null;
}

function cleanApiMessage(message: string) {
  if (message.includes("SQLSTATE") || message.includes("Integrity constraint violation")) {
    return "Data belum lengkap atau tidak valid. Periksa kembali form lalu coba lagi.";
  }

  return message;
}

export const api = {
  async login(payload: { email: string; password: string }) {
    return request<{ user: User; token: string }>("/login", {
      method: "POST",
      body: JSON.stringify(payload)
    });
  },
  async register(payload: {
    name: string;
    email: string;
    password: string;
    password_confirmation: string;
  }) {
    return request<{ user: User; token: string }>("/register", {
      method: "POST",
      body: JSON.stringify(payload)
    });
  },
  async logout() {
    return request<Record<string, never>>("/logout", { method: "POST" });
  },
  async me() {
    return request<{ user: User }>("/me");
  },
  async dashboard(filters?: Filters) {
    return request<DashboardSummary>(`/dashboard/summary${buildQuery(filters)}`);
  },
  async transactions(filters?: Filters) {
    return request<{ transactions: Transaction[] }>(`/transactions${buildQuery(filters)}`);
  },
  async transaction(id: string | number) {
    return request<{ transaction: Transaction }>(`/transactions/${id}`);
  },
  async createTransaction(payload: TransactionPayload) {
    return request<{ transaction: Transaction }>("/transactions", {
      method: "POST",
      body: JSON.stringify(payload)
    });
  },
  async updateTransaction(id: string | number, payload: TransactionPayload) {
    return request<{ transaction: Transaction }>(`/transactions/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload)
    });
  },
  async deleteTransaction(id: string | number) {
    return request<Record<string, never>>(`/transactions/${id}`, { method: "DELETE" });
  },
  async categories() {
    return request<{ categories: Category[] }>("/categories");
  },
  async category(id: string | number) {
    return request<{ category: Category }>(`/categories/${id}`);
  },
  async createCategory(payload: CategoryPayload) {
    return request<{ category: Category }>("/categories", {
      method: "POST",
      body: JSON.stringify(payload)
    });
  },
  async updateCategory(id: string | number, payload: CategoryPayload) {
    return request<{ category: Category }>(`/categories/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload)
    });
  },
  async deleteCategory(id: string | number) {
    return request<Record<string, never>>(`/categories/${id}`, { method: "DELETE" });
  },
  async userSettings() {
    return request<{ user_settings: UserSettings }>("/user-settings");
  },
  async updateUserSettings(payload: Partial<UserSettings>) {
    return request<{ user_settings: UserSettings }>("/user-settings", {
      method: "PUT",
      body: JSON.stringify(payload)
    });
  },
  async budgetAlerts() {
    return request<{ alerts: BudgetNotification[] }>("/budget-alerts");
  },
  async notifications() {
    return request<{ alerts: BudgetNotification[] }>("/notifications").catch((err) => {
      const message = err instanceof Error ? err.message : "";
      if (message.toLowerCase().includes("notifications") && message.toLowerCase().includes("route")) {
        return request<{ alerts: BudgetNotification[] }>("/budget-alerts");
      }

      throw err;
    });
  },
  async markNotificationRead(id: number) {
    return request<{ notification: { id: number; is_read: boolean } }>(`/notifications/${id}/read`, {
      method: "PATCH"
    });
  },
  async exchangeRates(base = "IDR") {
    return request<{ exchange_rates: ExchangeRate[] }>(`/exchange-rates${buildQuery({ base })}`);
  },
  async exportTransactionsPdf(filters?: Filters) {
    return download(`/transactions/export-pdf${buildQuery(filters)}`);
  }
};
