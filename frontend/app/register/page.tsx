import { AuthLayout } from "@/components/layout/AuthLayout";
import { AuthFormSwitcher } from "@/components/layout/AuthFormSwitcher";

export default function RegisterPage() {
  return (
    <AuthLayout
      eyebrow="Mulai catat keuangan"
      title="Budget, transaksi, dan saldo dalam satu tempat."
      description="Buat akun dan mulai catat keuangan."
    >
      <AuthFormSwitcher initialMode="register" />
    </AuthLayout>
  );
}
