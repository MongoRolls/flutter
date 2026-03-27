"use client";

import Link from "next/link";

import { ThemeToggle } from "@/components/theme-toggle";

export function FooterSection() {
  return (
    <footer className="border-t border-border/60 bg-kelem-bg/50 py-8 dark:border-white/10 dark:bg-background/80 sm:py-12">
      <div className="mx-auto flex max-w-6xl flex-col gap-5 px-4 sm:flex-row sm:items-start sm:justify-between sm:gap-8 sm:px-6">
        <div>
          <p className="text-sm font-semibold text-foreground">渴了么 KeLeME</p>
          <p className="mt-2 max-w-xs text-sm text-kelem-text-secondary">
            AI 智能饮水提醒，让补水更简单。
          </p>
        </div>
        <div className="flex flex-col gap-4 sm:items-end">
          <nav className="flex flex-wrap gap-x-5 gap-y-2 text-sm sm:gap-x-8 sm:gap-y-3" aria-label="页脚">
            <Link
              href="#features"
              className="text-kelem-text-secondary transition-colors hover:text-foreground"
            >
              功能
            </Link>
            <Link
              href="#download"
              className="text-kelem-text-secondary transition-colors hover:text-foreground"
            >
              下载
            </Link>
            {/* TODO: 替换为真实隐私政策 URL */}
            <span className="text-kelem-text-hint">隐私政策（占位）</span>
            {/* TODO: 替换为真实用户协议 URL */}
            <span className="text-kelem-text-hint">用户协议（占位）</span>
          </nav>
          <div className="flex items-center gap-2 sm:justify-end">
            <span className="text-xs text-kelem-text-hint">主题</span>
            <ThemeToggle />
          </div>
        </div>
      </div>
      <div className="mx-auto mt-6 max-w-6xl border-t border-border/50 px-4 pt-6 dark:border-white/10 sm:mt-10 sm:px-6 sm:pt-8">
        <p className="text-center text-xs text-kelem-text-hint">
          © {new Date().getFullYear()} KeLeME. 保留所有权利。
        </p>
      </div>
    </footer>
  );
}
