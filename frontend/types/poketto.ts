export type TransactionType = "income" | "expense";

export type User = {
  id: number;
  name: string;
  email: string;
};

export type Category = {
  id: number;
  user_id?: number;
  name: string;
  type: TransactionType;
  monthly_budget?: number | string | null;
};

export type Transaction = {
  id: number;
  user_id?: number;
  category_id: number | null;
  category_name?: string | null;
  type: TransactionType;
  amount: number;
  description?: string | null;
  transaction_date?: string | null;
  date?: string | null;
  location_lat?: number | null;
  location_lng?: number | null;
  location_name?: string | null;
  category?: Category | null;
};

export type UserSettings = {
  daily_budget: number;
  monthly_budget: number;
  currency: string;
  budget_warning_threshold?: number;
  notification_enabled: boolean;
  location_enabled: boolean;
};

export type ExchangeRate = {
  id?: number;
  base_currency: string;
  target_currency: string;
  rate: number | string;
  fetched_at?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
};

export type DashboardSummary = {
  total_income: number;
  total_expense: number;
  balance: number;
  daily_budget: number;
  monthly_budget: number;
  currency: string;
  period?: {
    start_date: string;
    end_date: string;
    label: string;
  };
  budget_warning_threshold: number;
  expense_trend: Array<{ date: string; label?: string; total: number }>;
  category_breakdown: Array<{ category: string; total: number }>;
  category_budgets: Array<{
    category_id: number;
    category_name: string;
    monthly_budget: number;
    spent: number;
    percentage: number;
  }>;
  recent_transactions: Transaction[];
  alerts: Array<{ id?: number; message?: string } | string>;
};

export type Filters = {
  start_date?: string;
  end_date?: string;
  month?: string;
  type?: TransactionType | "";
  category_id?: string;
};
