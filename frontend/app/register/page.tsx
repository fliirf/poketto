import { AuthLayout } from "@/components/layout/AuthLayout";
import { AuthFormSwitcher } from "@/components/layout/AuthFormSwitcher";

export default function RegisterPage() {
  return (
    <AuthLayout
      eyebrow="Personal finance tracker"
      title="Kelola uang harianmu."
      description="Catat transaksi dan pantau budget."
    >
      <AuthFormSwitcher initialMode="register" />
    </AuthLayout>
  );
}
