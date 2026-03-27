import { LandingPage } from "@/components/landing-page";
import { getApkUrl, getMacosUrl } from "@/lib/download-urls";

export default function Home() {
  return (
    <LandingPage apkUrl={getApkUrl()} macosUrl={getMacosUrl()} />
  );
}
