"use client";

import { motion, useReducedMotion } from "motion/react";
import Link from "next/link";

import { HeroWaterBg } from "@/components/hero-water-bg";
import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export function HeroSection() {
  const reduce = useReducedMotion();

  /* 勿对父级使用 opacity:0 → 子级会整片不可见；若动画未跑完或与 SSR 冲突会出现「只有背景气泡」 */
  const container = {
    hidden: { opacity: 1 },
    show: {
      opacity: 1,
      transition: {
        staggerChildren: reduce ? 0 : 0.11,
        delayChildren: reduce ? 0 : 0.08,
      },
    },
  };

  const item = {
    hidden: { opacity: 1, y: reduce ? 0 : 16 },
    show: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.52, ease: [0.22, 1, 0.36, 1] as const },
    },
  };

  return (
    <section
      id="top"
      className="relative overflow-hidden border-b border-border/50 pb-6 pt-10 dark:border-white/10 sm:pb-28 sm:pt-14"
    >
      <HeroWaterBg />
      <div className="relative z-10 mx-auto grid max-w-6xl items-center gap-8 px-4 sm:gap-12 sm:px-6 lg:grid-cols-[1.05fr_0.95fr] lg:gap-16">
        <motion.div
          variants={container}
          initial="hidden"
          animate="show"
          className="space-y-5 sm:space-y-8"
        >
          <motion.p
            variants={item}
            className="inline-flex items-center gap-2 rounded-full border border-primary/25 bg-card/70 px-3 py-1 text-xs font-medium text-kelem-text-secondary shadow-sm backdrop-blur-md dark:border-primary/30 dark:bg-card/50"
          >
            <span className="h-1.5 w-1.5 rounded-full bg-kelem-green shadow-[0_0_8px_rgba(76,175,80,0.8)]" />
            AI 驱动的饮水伴侣
          </motion.p>
          <motion.h1
            variants={item}
            className="text-balance text-3xl font-black tracking-tight text-foreground sm:text-5xl lg:text-[3.25rem] lg:leading-[1.12]"
          >
            渴了么
            <span className="text-kelem-text-secondary"> · </span>
            <span className="bg-gradient-to-r from-kelem-sky-deep to-kelem-green bg-clip-text text-transparent dark:from-kelem-sky-bright dark:to-kelem-green">
              KeLeME
            </span>
          </motion.h1>
          <motion.p
            variants={item}
            className="max-w-xl text-pretty text-base text-kelem-text-secondary sm:text-xl"
          >
            AI 帮你养成饮水好习惯。智能打卡、个性化计划与温柔提醒，让补水成为自然节奏。
          </motion.p>
          <motion.div
            variants={item}
            className="flex flex-row gap-3 sm:flex-wrap sm:items-center"
          >
            <Link
              href="#download"
              className={cn(
                buttonVariants({ size: "lg" }),
                "h-12 flex-1 rounded-[14px] px-4 text-base shadow-[0_4px_24px_rgba(41,182,246,0.4)] transition-transform duration-300 hover:scale-[1.04] hover:shadow-[0_6px_32px_rgba(41,182,246,0.55)] sm:h-11 sm:flex-none sm:px-6"
              )}
            >
              下载应用
            </Link>
            <Link
              href="#features"
              className={cn(
                buttonVariants({ variant: "outline", size: "lg" }),
                "h-12 flex-1 rounded-[14px] border-border/80 bg-card/50 px-4 text-base backdrop-blur-md dark:border-white/15 sm:h-11 sm:flex-none sm:px-6"
              )}
            >
              了解更多
            </Link>
          </motion.div>
        </motion.div>

        <motion.div
          initial={reduce ? false : { opacity: 1, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{
            duration: 0.65,
            delay: 0.15,
            ease: [0.22, 1, 0.36, 1] as const,
          }}
          className="relative mx-auto hidden w-full max-w-sm sm:block lg:mx-0 lg:max-w-none"
        >
          <div className="relative mx-auto aspect-[10/19] w-[min(100%,320px)] rounded-[2.25rem] border border-white/70 bg-gradient-to-b from-card to-muted/40 p-2 shadow-[0_24px_80px_rgba(41,182,246,0.18)] backdrop-blur-md dark:border-white/10 dark:from-card dark:to-kelem-card dark:shadow-[0_24px_80px_rgba(0,0,0,0.45)]">
            <div className="flex h-full w-full flex-col overflow-hidden rounded-[1.85rem] bg-gradient-to-b from-kelem-bg to-card dark:from-background dark:to-kelem-card">
              <div className="flex items-center justify-between px-4 pb-2 pt-3">
                <span className="text-xs text-kelem-text-hint">9:41</span>
                <div className="h-5 w-16 rounded-full bg-foreground/10 dark:bg-white/10" />
              </div>
              <div className="flex flex-1 flex-col gap-4 px-4 pb-6 pt-2">
                <div className="rounded-2xl bg-card/90 p-4 shadow-[0_2px_12px_rgba(0,0,0,0.06)] dark:bg-white/5">
                  <p className="text-xs text-kelem-text-hint">今日饮水</p>
                  <p className="mt-2 font-mono text-3xl font-bold tabular-nums text-foreground">
                    1,280
                    <span className="text-lg text-kelem-text-secondary"> ml</span>
                  </p>
                </div>
                <div className="flex flex-1 flex-col justify-center rounded-2xl border border-dashed border-border/80 bg-muted/30 px-3 py-5 dark:border-white/10 dark:bg-white/5">
                  <p className="text-center text-xs font-medium text-kelem-text-secondary">
                    本周饮水趋势
                  </p>
                  <div className="mt-3 flex h-16 items-end justify-center gap-1.5">
                    {[42, 58, 36, 72, 48, 66, 52].map((h, i) => (
                      <div
                        key={i}
                        className="w-2 rounded-full bg-gradient-to-t from-kelem-sky-deep/55 to-kelem-green/65"
                        style={{ height: `${h}%` }}
                      />
                    ))}
                  </div>
                  <p className="mt-2 text-center text-[11px] leading-snug text-kelem-text-hint">
                    示意预览 · 完整数据在 App 内
                  </p>
                </div>
              </div>
            </div>
          </div>
          <div
            className="pointer-events-none absolute -right-6 -top-6 h-24 w-24 rounded-full bg-kelem-pink/15 blur-2xl dark:bg-kelem-pink/25"
            aria-hidden
          />
        </motion.div>
      </div>
    </section>
  );
}
