"use client";

import { DownloadSection } from "@/components/sections/download-section";
import { FeaturesSection } from "@/components/sections/features-section";
import { FooterSection } from "@/components/sections/footer-section";
import { HeroSection } from "@/components/sections/hero-section";
import { WorkflowSection } from "@/components/sections/workflow-section";
import { SiteHeader } from "@/components/site-header";

export type LandingPageProps = {
  apkUrl: string;
  macosUrl: string;
};

export function LandingPage({ apkUrl, macosUrl }: LandingPageProps) {
  return (
    <div className="flex min-h-full flex-col">
      <SiteHeader />
      {/* 勿使用 flex-1：会把 main 撑满视口，在最后一屏内容与 Footer 之间留下大块空白 */}
      <main>
        <HeroSection />
        <FeaturesSection />
        <WorkflowSection />
        <DownloadSection apkUrl={apkUrl} macosUrl={macosUrl} />
      </main>
      <FooterSection />
    </div>
  );
}
