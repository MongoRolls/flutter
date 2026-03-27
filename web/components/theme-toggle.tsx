"use client";

import { useTheme } from "next-themes";
import * as React from "react";

import { cn } from "@/lib/utils";

function MoonIcon() {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="18"
      height="18"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden={true}
    >
      <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z" />
    </svg>
  );
}

function SunIcon() {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="18"
      height="18"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden={true}
    >
      <circle cx="12" cy="12" r="4" />
      <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41" />
    </svg>
  );
}

export function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  const isDark = resolvedTheme === "dark";
  const showSun = mounted && isDark;

  return (
    <button
      type="button"
      data-kelem-theme-toggle=""
      disabled={!mounted}
      aria-busy={!mounted}
      aria-label={
        mounted
          ? isDark
            ? "切换到浅色模式"
            : "切换到深色模式"
          : "主题切换（加载中）"
      }
      aria-pressed={mounted ? isDark : undefined}
      onClick={() => setTheme(isDark ? "light" : "dark")}
      className={cn(
        "inline-flex size-8 shrink-0 items-center justify-center rounded-[14px] border",
        "text-sm font-medium outline-none transition-all",
        "border-border/80 bg-card/60 backdrop-blur-md",
        "hover:bg-muted focus-visible:ring-2 focus-visible:ring-ring",
        "dark:border-white/10 dark:bg-card/40 dark:hover:bg-muted/50",
        "disabled:cursor-default disabled:opacity-100",
        mounted && "cursor-pointer"
      )}
    >
      <span className="pointer-events-none inline-flex transition-transform duration-300">
        {showSun ? <SunIcon /> : <MoonIcon />}
      </span>
    </button>
  );
}
