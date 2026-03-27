import type { Metadata } from "next";
import { Noto_Sans_SC, Space_Mono } from "next/font/google";

import { ThemeProvider } from "@/components/providers/theme-provider";

import "./globals.css";

const notoSansSc = Noto_Sans_SC({
  subsets: ["latin"],
  variable: "--font-sans",
  weight: ["400", "500", "600", "700"],
  display: "swap",
});

const spaceMono = Space_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
  weight: ["400", "700"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "渴了么 KeLeME — AI 智能饮水提醒",
  description:
    "AI 帮你养成饮水好习惯。智能打卡、饮水计划、对话与提醒，让每一杯水都恰到好处。",
  keywords: ["KeLeME", "渴了么", "饮水", "健康", "AI", "提醒"],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="zh-CN"
      className={`${notoSansSc.variable} ${spaceMono.variable} h-full`}
      suppressHydrationWarning
    >
      <body
        className="min-h-full flex flex-col bg-background font-sans text-foreground transition-colors"
        suppressHydrationWarning
      >
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
