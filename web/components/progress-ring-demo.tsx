"use client";

import { motion, useReducedMotion } from "motion/react";
import * as React from "react";

import { cn } from "@/lib/utils";

const SIZE = 120;
const STROKE = 10;
const R = (SIZE - STROKE) / 2;
const C = 2 * Math.PI * R;

type ProgressRingDemoProps = {
  className?: string;
  /** 0–100 */
  value?: number;
};

/**
 * Features 区示意：天蓝 → 绿渐变环（SVG），与 App 进度环气质一致。
 */
export function ProgressRingDemo({ className, value = 72 }: ProgressRingDemoProps) {
  const reduce = useReducedMotion();
  const offset = C - (value / 100) * C;

  return (
    <div className={cn("relative flex items-center justify-center", className)}>
      <svg
        width={SIZE}
        height={SIZE}
        viewBox={`0 0 ${SIZE} ${SIZE}`}
        className="drop-shadow-sm"
        aria-hidden
      >
        <defs>
          <linearGradient id="kelem-ring-grad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#29B6F6" />
            <stop offset="55%" stopColor="#4FC3F7" />
            <stop offset="100%" stopColor="#4CAF50" />
          </linearGradient>
        </defs>
        <circle
          cx={SIZE / 2}
          cy={SIZE / 2}
          r={R}
          fill="none"
          stroke="currentColor"
          strokeWidth={STROKE}
          className="text-border/80 dark:text-white/10"
        />
        <motion.circle
          cx={SIZE / 2}
          cy={SIZE / 2}
          r={R}
          fill="none"
          stroke="url(#kelem-ring-grad)"
          strokeWidth={STROKE}
          strokeLinecap="round"
          strokeDasharray={C}
          initial={reduce ? { strokeDashoffset: offset } : { strokeDashoffset: C }}
          animate={{ strokeDashoffset: offset }}
          transition={
            reduce
              ? { duration: 0 }
              : { duration: 1.35, ease: [0.22, 1, 0.36, 1] as const }
          }
          transform={`rotate(-90 ${SIZE / 2} ${SIZE / 2})`}
        />
      </svg>
      <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
        <span className="font-mono text-2xl font-bold tabular-nums text-foreground">
          {value}
          <span className="text-base text-kelem-text-secondary">%</span>
        </span>
        <span className="text-xs text-kelem-text-hint">今日目标</span>
      </div>
    </div>
  );
}
