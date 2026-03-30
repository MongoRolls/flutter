import { existsSync } from "node:fs";
import { join } from "node:path";

import { LandingPage } from "@/components/landing-page";
import { getApkUrl, getIosUrl, getMacosUrl } from "@/lib/download-urls";

export default function Home() {
  const iosPath = join(process.cwd(), "public", "ke-le-me-ios.ipa");
  const iosUrl = existsSync(iosPath) ? getIosUrl() : undefined;

  return (
    <LandingPage
      apkUrl={getApkUrl()}
      macosUrl={getMacosUrl()}
      iosUrl={iosUrl}
    />
  );
}
