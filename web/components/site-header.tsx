"use client";

import { useState } from "react";
import Link from "next/link";
import { Menu, X } from "lucide-react";

import { ThemeToggle } from "@/components/theme-toggle";
import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const nav = [
  { href: "#features", label: "功能" },
  { href: "#workflow", label: "工作流程" },
  { href: "#download", label: "下载" },
] as const;

export function SiteHeader({ className }: { className?: string }) {
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <header
      className={cn(
        "sticky top-0 z-100 border-b border-border/60 bg-kelem-bg/80 backdrop-blur-xl dark:border-white/10 dark:bg-background/80",
        className
      )}
    >
      <div className="pointer-events-auto mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-4 sm:px-6">
        <Link
          href="#top"
          className="flex items-center gap-2 text-lg font-semibold tracking-tight text-foreground"
          onClick={() => setMobileOpen(false)}
        >
          <span
            className="flex h-9 w-9 items-center justify-center rounded-2xl bg-primary text-sm font-bold text-primary-foreground shadow-[0_2px_12px_rgba(41,182,246,0.35)]"
            aria-hidden
          >
            水
          </span>
          <span className="hidden sm:inline">渴了么</span>
          <span className="text-xs font-medium text-kelem-text-secondary sm:ml-1">
            KeLeME
          </span>
        </Link>
        <nav className="hidden items-center gap-1 md:flex" aria-label="页面导航">
          {nav.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                buttonVariants({ variant: "ghost", size: "sm" }),
                "text-kelem-text-secondary hover:text-foreground"
              )}
            >
              {item.label}
            </Link>
          ))}
        </nav>
        <div className="relative z-110 flex items-center gap-2">
          <ThemeToggle />
          <Link
            href="#download"
            className={cn(
              buttonVariants({ size: "sm" }),
              "hidden rounded-[14px] shadow-[0_2px_16px_rgba(41,182,246,0.35)] transition-transform duration-300 hover:scale-[1.03] hover:shadow-[0_4px_28px_rgba(41,182,246,0.45)] sm:inline-flex"
            )}
          >
            立即下载
          </Link>
          {/* 汉堡按钮：仅 md 以下可见 */}
          <button
            type="button"
            aria-label={mobileOpen ? "关闭菜单" : "打开菜单"}
            aria-expanded={mobileOpen}
            onClick={() => setMobileOpen((v) => !v)}
            className="flex h-9 w-9 items-center justify-center rounded-xl text-kelem-text-secondary transition-colors hover:bg-muted hover:text-foreground md:hidden"
          >
            {mobileOpen ? <X className="size-5" /> : <Menu className="size-5" />}
          </button>
        </div>
      </div>

      {/* 移动端下拉导航 */}
      {mobileOpen && (
        <nav
          className="border-t border-border/50 bg-kelem-bg/95 px-4 pb-4 pt-2 backdrop-blur-xl dark:border-white/10 dark:bg-background/95 md:hidden"
          aria-label="移动端导航"
        >
          <ul className="flex flex-col gap-1">
            {nav.map((item) => (
              <li key={item.href}>
                <Link
                  href={item.href}
                  onClick={() => setMobileOpen(false)}
                  className="flex w-full items-center rounded-xl px-3 py-2.5 text-base font-medium text-kelem-text-secondary transition-colors hover:bg-muted hover:text-foreground"
                >
                  {item.label}
                </Link>
              </li>
            ))}
            <li className="mt-2">
              <Link
                href="#download"
                onClick={() => setMobileOpen(false)}
                className={cn(
                  buttonVariants({ size: "default" }),
                  "w-full rounded-[14px] shadow-[0_2px_16px_rgba(41,182,246,0.35)]"
                )}
              >
                立即下载
              </Link>
            </li>
          </ul>
        </nav>
      )}
    </header>
  );
}
