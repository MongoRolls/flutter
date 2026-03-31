"use client";

import {
  Bell,
  Droplets,
  MessageCircle,
  Sparkles,
  Target,
  Users,
} from "lucide-react";

import { GlassCard } from "@/components/glass-card";
import { ProgressRingDemo } from "@/components/progress-ring-demo";
import { SectionReveal } from "@/components/section-reveal";
import { cn } from "@/lib/utils";

const features = [
  {
    title: "智能打卡",
    desc: "记录每一杯水，清晰看见自己的节奏。",
    icon: Target,
    accent: "text-kelem-green",
    mobileBg: "bg-kelem-green/10 dark:bg-kelem-green/15",
  },
  {
    title: "AI 饮水计划",
    desc: "根据作息与目标生成可执行计划。",
    icon: Sparkles,
    accent: "text-primary",
    mobileBg: "bg-primary/10 dark:bg-primary/15",
  },
  {
    title: "AI 对话",
    desc: "随时询问饮水建议与小贴士。",
    icon: MessageCircle,
    accent: "text-kelem-sky-deep dark:text-kelem-sky-bright",
    mobileBg: "bg-kelem-sky/10 dark:bg-kelem-sky/15",
  },
  {
    title: "心连心",
    desc: "让每一杯水都有温度。",
    icon: Users,
    accent: "text-kelem-pink",
    mobileBg: "bg-kelem-pink/10 dark:bg-kelem-pink/15",
  },
  {
    title: "智能提醒",
    desc: "多种风格，合适时间轻轻叫你喝水。",
    icon: Bell,
    accent: "text-kelem-orange",
    mobileBg: "bg-kelem-orange/10 dark:bg-kelem-orange/15",
  },
] as const;

export function FeaturesSection() {
  return (
    <SectionReveal
      id="features"
      className="border-b border-border/50 pb-12 pt-8 dark:border-white/10 sm:py-20"
    >
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="mb-6 max-w-2xl sm:mb-12">
          <h2 className="text-2xl font-bold tracking-tight text-foreground sm:text-4xl">
            核心功能
          </h2>
          <p className="mt-2 text-base text-kelem-text-secondary sm:mt-3 sm:text-lg">
            为日常饮水场景设计，一眼看懂、一步上手。
          </p>
        </div>

        {/* ── 移动端：2 列紧凑卡片网格（md 以下） ── */}
        <div className="grid grid-cols-2 gap-3 md:hidden">
          {features.map((f) => (
            <div
              key={f.title}
              className="rounded-2xl border border-white/70 bg-card/95 p-4 shadow-[0_2px_10px_rgba(0,0,0,0.05)] dark:border-white/10 dark:bg-card/80"
            >
              {/* 图标块：用功能自身的 accent 色做底 */}
              <span
                className={cn(
                  "mb-3 flex h-9 w-9 items-center justify-center rounded-xl",
                  f.mobileBg,
                  f.accent
                )}
              >
                <f.icon className="size-4" aria-hidden />
              </span>
              <h3 className="text-sm font-semibold text-foreground">
                {f.title}
              </h3>
              <p className="mt-1 text-xs leading-relaxed text-kelem-text-secondary">
                {f.desc}
              </p>
            </div>
          ))}

          {/* 第 6 格：今日进度数字卡（渐变背景，不用 SVG 环——移动端格子太窄） */}
          <div className="flex flex-col items-center justify-center gap-1 rounded-2xl border border-primary/20 bg-gradient-to-br from-primary/10 via-kelem-sky/5 to-kelem-green/10 p-4 shadow-[0_2px_10px_rgba(41,182,246,0.08)] dark:border-primary/20 dark:from-primary/15 dark:to-kelem-green/15">
            <div className="flex items-end gap-0.5">
              <span className="font-mono text-3xl font-black tabular-nums leading-none text-foreground">
                72
              </span>
              <span className="mb-0.5 text-sm font-semibold text-kelem-text-secondary">
                %
              </span>
            </div>
            <span className="text-xs font-medium text-kelem-text-hint">
              今日目标
            </span>
            <div className="mt-1.5 flex items-center gap-1">
              <Droplets className="size-3 text-primary" aria-hidden />
              <span className="font-mono text-[11px] tabular-nums text-kelem-text-secondary">
                1,440 ml
              </span>
            </div>
          </div>
        </div>

        {/* ── 桌面端：原三列网格（md+ 保持不变） ── */}
        <div className="hidden md:grid md:grid-cols-2 md:gap-4 lg:grid-cols-3 lg:gap-5">
          {features.map((f) => (
            <GlassCard
              key={f.title}
              className="group hover:-translate-y-1 hover:shadow-[0_12px_40px_rgba(41,182,246,0.12)] dark:hover:shadow-[0_12px_48px_rgba(79,195,247,0.12)]"
            >
              <div className="flex items-start gap-4">
                <span
                  className={cn(
                    "flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-muted/80 dark:bg-white/5",
                    f.accent
                  )}
                >
                  <f.icon className="size-5" aria-hidden />
                </span>
                <div>
                  <h3 className="text-base font-semibold text-foreground">
                    {f.title}
                  </h3>
                  <p className="mt-1 text-sm leading-relaxed text-kelem-text-secondary">
                    {f.desc}
                  </p>
                </div>
              </div>
            </GlassCard>
          ))}

          <GlassCard className="flex flex-col items-center justify-center gap-4 md:col-span-1 lg:row-span-1">
            <div className="flex items-center gap-2 text-sm font-medium text-kelem-text-secondary">
              <Droplets className="size-4 text-primary" aria-hidden />
              今日进度示意
            </div>
            <ProgressRingDemo />
          </GlassCard>
        </div>
      </div>
    </SectionReveal>
  );
}
