import { AuthLayout } from "@/components/layout/AuthLayout";
import { AuthFormSwitcher } from "@/components/layout/AuthFormSwitcher";

export default function LoginPage() {
  return (
    <AuthLayout
      eyebrow="Personal finance tracker"
      title="Kelola uang harian tanpa ribet."
      description="Kelola pemasukan, pengeluaran, dan budget harianmu."
    >
      <AuthFormSwitcher initialMode="login" />
    </AuthLayout>
  );
}
