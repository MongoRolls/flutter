"use client";

import type { LucideIcon } from "lucide-react";
import { Apple, Download, MonitorSmartphone, Smartphone } from "lucide-react";
import Link from "next/link";

import { GlassCard } from "@/components/glass-card";
import { SectionReveal } from "@/components/section-reveal";
import { Button, buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

type DownloadSectionProps = {
  apkUrl: string;
  macosUrl: string;
};

export function DownloadSection({ apkUrl, macosUrl }: DownloadSectionProps) {
  return (
    <SectionReveal
      id="download"
      className="border-b border-border/50 py-12 dark:border-white/10 sm:py-20"
    >
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="mb-8 max-w-2xl sm:mb-10">
          <h2 className="text-2xl font-bold tracking-tight text-foreground sm:text-3xl sm:text-4xl">
            下载与体验
          </h2>
          <p className="mt-2 text-base text-kelem-text-secondary sm:mt-3 sm:text-lg">
            当前提供 Android APK 与 macOS 安装包；更多平台陆续到来。
          </p>
        </div>

        {/* ── 移动端专属布局（md 以下） ── */}
        <div className="flex flex-col gap-3 md:hidden">
          {/* 主下载按钮 */}
          <GlassCard className="flex flex-col gap-3 p-5">
            <p className="text-xs font-semibold uppercase tracking-widest text-kelem-text-hint">
              立即下载
            </p>
            <Link
              href={apkUrl}
              download
              aria-label="下载 Android APK 安装包"
              className={cn(
                buttonVariants({ size: "lg" }),
                "h-12 w-full gap-2.5 rounded-[14px] shadow-[0_4px_24px_rgba(41,182,246,0.35)]"
              )}
            >
              <Smartphone className="size-5" aria-hidden />
              Android APK
            </Link>

            <Link
              href={macosUrl}
              download
              aria-label="下载 macOS 应用 zip 压缩包"
              className={cn(
                buttonVariants({ variant: "outline", size: "lg" }),
                "h-12 w-full gap-2.5 rounded-[14px]"
              )}
            >
              <Apple className="size-5" aria-hidden />
              macOS（zip）
            </Link>
          </GlassCard>

          {/* 即将推出的平台——紧凑小行 */}
          <div className="flex gap-3">
            <div className="flex flex-1 items-center justify-between rounded-2xl border border-border/60 bg-muted/40 px-4 py-3 dark:border-white/10 dark:bg-white/5">
              <div className="flex items-center gap-2">
                <Apple className="size-4 text-kelem-text-hint" aria-hidden />
                <span className="text-sm font-medium text-kelem-text-secondary">iOS</span>
              </div>
              <span className="text-xs text-kelem-text-hint">即将推出</span>
            </div>
            <div className="flex flex-1 items-center justify-between rounded-2xl border border-border/60 bg-muted/40 px-4 py-3 dark:border-white/10 dark:bg-white/5">
              <div className="flex items-center gap-2">
                <MonitorSmartphone className="size-4 text-kelem-text-hint" aria-hidden />
                <span className="text-sm font-medium text-kelem-text-secondary">PC</span>
              </div>
              <span className="text-xs text-kelem-text-hint">即将推出</span>
            </div>
          </div>
        </div>

        {/* ── 桌面端布局（md+，原有四格卡片） ── */}
        <div className="hidden md:grid md:grid-cols-2 md:gap-4 lg:grid-cols-4">
          <PlatformCard
            title="Android"
            subtitle="APK 安装包"
            icon={Smartphone}
            iconClassName="text-kelem-green"
            available
            href={apkUrl}
          />
          <PlatformCard
            title="macOS"
            subtitle="zip 解压后拖入「应用程序」"
            icon={Apple}
            iconClassName="text-kelem-text-secondary"
            available
            href={macosUrl}
          />
          <PlatformCard
            title="iOS"
            subtitle="App Store"
            icon={Apple}
            iconClassName="text-kelem-text-hint"
            comingSoon
          />
          <PlatformCard
            title="PC"
            subtitle="Windows 等"
            icon={MonitorSmartphone}
            iconClassName="text-kelem-text-hint"
            comingSoon
          />
        </div>
      </div>
    </SectionReveal>
  );
}

type PlatformCardProps = {
  title: string;
  subtitle: string;
  icon: LucideIcon;
  iconClassName?: string;
  available?: boolean;
  href?: string;
  envHint?: string;
  comingSoon?: boolean;
};

function PlatformCard({
  title,
  subtitle,
  icon: Icon,
  iconClassName,
  available,
  href,
  envHint,
  comingSoon,
}: PlatformCardProps) {
  const canDownload = Boolean(available && href);

  return (
    <GlassCard className="flex flex-col gap-4 p-5 hover:-translate-y-1 hover:shadow-[0_12px_40px_rgba(41,182,246,0.12)] dark:hover:shadow-[0_12px_48px_rgba(79,195,247,0.12)]">
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-center gap-3">
          <span
            className={cn(
              "flex h-11 w-11 items-center justify-center rounded-2xl bg-muted/80 dark:bg-white/5",
              iconClassName
            )}
          >
            <Icon className="size-5" aria-hidden />
          </span>
          <div>
            <h3 className="text-base font-semibold text-foreground">{title}</h3>
            <p className="text-xs text-kelem-text-hint">{subtitle}</p>
          </div>
        </div>
        {comingSoon ? (
          <span className="shrink-0 rounded-full bg-muted px-2 py-0.5 text-[10px] font-medium uppercase tracking-wide text-kelem-text-secondary dark:bg-white/10">
            即将推出
          </span>
        ) : null}
      </div>

      {comingSoon ? (
        <Button
          type="button"
          disabled
          className="h-11 w-full rounded-[14px]"
          aria-disabled="true"
          aria-label={`${title} 版本即将推出，暂不可下载`}
        >
          敬请期待
        </Button>
      ) : canDownload ? (
        <Link
          href={href!}
          download
          aria-label={`下载 ${title} 安装包`}
          className={cn(
            buttonVariants({ variant: "default", size: "default" }),
            "h-11 w-full gap-2 rounded-[14px] shadow-[0_2px_16px_rgba(41,182,246,0.35)] transition-transform duration-300 hover:scale-[1.02] hover:shadow-[0_4px_28px_rgba(41,182,246,0.45)]"
          )}
        >
          <Download className="size-4" aria-hidden />
          下载
        </Link>
      ) : (
        <Button
          type="button"
          disabled
          className="h-11 w-full rounded-[14px]"
          aria-disabled="true"
          title={envHint ? `请在环境变量中配置 ${envHint}` : undefined}
        >
          尚未配置下载链接
        </Button>
      )}
    </GlassCard>
  );
}
