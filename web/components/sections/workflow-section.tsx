"use client";

import { motion, useReducedMotion } from "motion/react";
import { Bell, SlidersHorizontal, Sparkles } from "lucide-react";

import { GlassCard } from "@/components/glass-card";
import { SectionReveal } from "@/components/section-reveal";

const steps = [
  {
    title: "目标设定",
    desc: "录入作息、体重与偏好等参数，自动生成每日饮水目标。",
    icon: SlidersHorizontal,
  },
  {
    title: "智能计划",
    desc: "结合个人习惯与使用场景，生成可执行的饮水节奏与时段安排。",
    icon: Sparkles,
  },
  {
    title: "提醒与记录",
    desc: "在预设时段内推送提醒，并支持饮水记录与数据汇总。",
    icon: Bell,
  },
] as const;

export function WorkflowSection() {
  const reduce = useReducedMotion();

  return (
    <SectionReveal
      id="workflow"
      className="border-b border-border/50 py-12 dark:border-white/10 sm:py-20"
    >
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="mb-8 max-w-2xl sm:mb-12">
          <h2 className="text-2xl font-bold tracking-tight text-foreground sm:text-3xl sm:text-4xl" >
            工作流程
          </h2>
          <p className="mt-2 text-base text-kelem-text-secondary sm:mt-3 sm:text-lg">
            从目标设定、计划生成到提醒与记录，形成完整闭环。
          </p>
        </div>

        <div className="flex flex-col gap-3 sm:grid sm:grid-cols-3 sm:gap-5">
          {steps.map((step, i) => (
            <motion.div
              key={step.title}
              initial={reduce ? false : { opacity: 1, y: 24 }}
              whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
              viewport={{ once: true, amount: 0.35 }}
              transition={{
                duration: 0.5,
                delay: reduce ? 0 : i * 0.12,
                ease: [0.22, 1, 0.36, 1] as const,
              }}
            >
              <GlassCard className="relative h-full hover:-translate-y-1 hover:shadow-[0_12px_40px_rgba(41,182,246,0.1)] dark:hover:shadow-[0_12px_48px_rgba(79,195,247,0.1)]">
                {/* 移动端：icon 左，内容右；sm+：竖排 */}
                <div className="flex items-start gap-4 sm:block">
                  <div className="shrink-0 sm:mb-4">
                    <div className="inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-primary/12 text-primary dark:bg-primary/20">
                      <step.icon className="size-5" aria-hidden />
                    </div>
                  </div>
                  <div className="flex-1">
                    <p className="font-mono text-xs tabular-nums text-kelem-text-hint">
                      STEP {String(i + 1).padStart(2, "0")}
                    </p>
                    <h3 className="mt-1 text-base font-semibold text-foreground sm:mt-2 sm:text-lg">
                      {step.title}
                    </h3>
                    <p className="mt-1 text-sm leading-relaxed text-kelem-text-secondary sm:mt-2">
                      {step.desc}
                    </p>
                  </div>
                </div>
              </GlassCard>
            </motion.div>
          ))}
        </div>
      </div>
    </SectionReveal>
  );
}
