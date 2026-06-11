import type { Metadata } from "next";
import { Oswald, Playfair_Display } from "next/font/google";
import { ToastProvider } from "@/components/ui/ToastProvider";
import { AuthProvider } from "@/lib/auth";
import "./globals.css";

const playfair = Playfair_Display({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-heading"
});

const oswald = Oswald({
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
      <body className={`${playfair.variable} ${oswald.variable}`}>
        <AuthProvider>
          <ToastProvider>{children}</ToastProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
