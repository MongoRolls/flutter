import * as React from "react";

import { cn } from "@/lib/utils";

type GlassCardProps = React.HTMLAttributes<HTMLDivElement>;

/**
 * KeLeME GlassCard：大圆角、浅阴影；深色下玻璃态 + 可选微光。
 */
export function GlassCard({ className, ...props }: GlassCardProps) {
  return (
    <div
      className={cn(
        "rounded-2xl border border-white/60 bg-card/95 p-4 shadow-[0_2px_12px_rgba(0,0,0,0.06)] backdrop-blur-md transition-[transform,box-shadow] duration-300 dark:border-white/10 dark:bg-card/75 dark:shadow-[0_0_48px_-20px_rgba(79,195,247,0.35)] sm:p-6",
        className
      )}
      {...props}
    />
  );
}
