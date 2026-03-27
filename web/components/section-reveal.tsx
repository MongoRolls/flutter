"use client";

import { motion, useReducedMotion } from "motion/react";
import * as React from "react";

import { cn } from "@/lib/utils";

type SectionRevealProps = React.ComponentProps<typeof motion.section> & {
  children: React.ReactNode;
};

/**
 * 滚动入场：whileInView 一次，避免重复骚扰。
 */
export function SectionReveal({ children, className, ...props }: SectionRevealProps) {
  const reduce = useReducedMotion();

  return (
    <motion.section
      /* 避免 initial opacity:0 — 未触发 whileInView 时会出现整段空白 */
      initial={reduce ? false : { opacity: 1, y: 28 }}
      whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.08, margin: "0px 0px 80px 0px" }}
      transition={{ duration: 0.55, ease: [0.22, 1, 0.36, 1] as const }}
      className={cn(className)}
      {...props}
    >
      {children}
    </motion.section>
  );
}
