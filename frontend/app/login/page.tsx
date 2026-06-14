import { AuthLayout } from "@/components/layout/AuthLayout";
import { AuthFormSwitcher } from "@/components/layout/AuthFormSwitcher";

export default function LoginPage() {
  return (
    <AuthLayout
      eyebrow="Personal finance tracker"
      title="Kelola uang harian tanpa ribet."
      description="Masuk ke dashboard keuanganmu."
    >
      <AuthFormSwitcher initialMode="login" />
    </AuthLayout>
  );
}
