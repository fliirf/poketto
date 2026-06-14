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

export type BudgetNotification = {
  id: number;
  user_id?: number;
  category_id?: number | null;
  type: "daily_budget" | "monthly_budget" | "category_budget" | string;
  alert_type?: string;
  title?: string | null;
  message: string;
  threshold_value?: number;
  current_value?: number;
  period_date?: string | null;
  period_month?: string | null;
  is_read: boolean;
  created_at?: string | null;
  updated_at?: string | null;
};

export type DashboardSummary = {
  total_income: number;
  total_expense: number;
  balance: number;
  daily_budget: number;
  daily_expense: number;
  daily_budget_remaining: number;
  daily_budget_percentage: number;
  monthly_budget: number;
  monthly_expense: number;
  monthly_budget_remaining: number;
  monthly_budget_percentage: number;
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
  alerts: BudgetNotification[];
};

export type Filters = {
  start_date?: string;
  end_date?: string;
  month?: string;
  type?: TransactionType | "";
  category_id?: string;
};
