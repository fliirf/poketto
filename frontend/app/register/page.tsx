import { AuthLayout } from "@/components/layout/AuthLayout";
import { AuthFormSwitcher } from "@/components/layout/AuthFormSwitcher";

export default function RegisterPage() {
  return (
    <AuthLayout
      eyebrow="Personal finance tracker"
      title="Budget, transaksi, dan saldo dalam satu tempat."
      description="Kelola pemasukan, pengeluaran, dan budget harianmu."
    >
      <AuthFormSwitcher initialMode="register" />
    </AuthLayout>
  );
}
