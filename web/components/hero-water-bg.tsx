"use client";

/**
 * Hero 背景：轻量「水」氛围（渐变 + 气泡），性能友好。
 */
export function HeroWaterBg() {
  return (
    <div
      className="pointer-events-none absolute inset-0 z-0 overflow-hidden"
      aria-hidden
    >
      <div className="absolute -left-1/4 top-0 h-[120%] w-[70%] rounded-full bg-gradient-to-br from-primary/15 via-transparent to-kelem-green/10 blur-3xl dark:from-primary/25 dark:to-kelem-green/15" />
      <div className="absolute -right-1/4 bottom-0 h-[90%] w-[60%] rounded-full bg-gradient-to-tl from-kelem-sky-deep/10 via-transparent to-kelem-pink/10 blur-3xl dark:from-kelem-sky-bright/15" />
      <div className="kelem-bubble left-[8%] top-[18%] h-[120px] w-[120px]" />
      <div className="kelem-bubble right-[12%] top-[28%] h-[72px] w-[72px] [animation-delay:-3s]" />
      <div className="kelem-bubble bottom-[20%] left-[22%] h-12 w-12 [animation-delay:-6s]" />
      <div className="kelem-bubble bottom-[12%] right-[20%] h-[90px] w-[90px] [animation-delay:-9s]" />
    </div>
  );
}
