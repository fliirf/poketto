import type { Metadata } from "next";
import { Baloo_2, Inter, Plus_Jakarta_Sans } from "next/font/google";
import { RouteTransitionLoader } from "@/components/layout/RouteTransitionLoader";
import { ToastProvider } from "@/components/ui/ToastProvider";
import { AuthProvider } from "@/lib/auth";
import "./globals.css";

const baloo = Baloo_2({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-brand"
});

const jakarta = Plus_Jakarta_Sans({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-heading"
});

const inter = Inter({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-body"
});

export const metadata: Metadata = {
  title: {
    default: "Poketto",
    template: "%s | Poketto"
  },
  description: "Poketto finance dashboard untuk mengelola transaksi, budget, kategori, laporan, dan kurs mata uang.",
  icons: {
    icon: "/favicon.png",
    shortcut: "/favicon.png",
    apple: "/icon-192.png"
  }
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="id">
      <body className={`${baloo.variable} ${jakarta.variable} ${inter.variable}`}>
        <AuthProvider>
          <ToastProvider>{children}</ToastProvider>
          <RouteTransitionLoader />
        </AuthProvider>
      </body>
    </html>
  );
}
