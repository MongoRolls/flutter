/**
 * 默认使用 `public/` 下静态文件；部署到 CDN 时可设
 * NEXT_PUBLIC_DOWNLOAD_APK_URL / NEXT_PUBLIC_DOWNLOAD_MACOS_URL 覆盖。
 */
const defaultApkPath = "/ke-le-me-release.apk";
const defaultMacosZipPath = "/ke-le-me-macos.zip";

export function getApkUrl(): string {
  const u = process.env.NEXT_PUBLIC_DOWNLOAD_APK_URL;
  return u != null && u.trim().length > 0 ? u.trim() : defaultApkPath;
}

export function getMacosUrl(): string {
  const u = process.env.NEXT_PUBLIC_DOWNLOAD_MACOS_URL;
  return u != null && u.trim().length > 0 ? u.trim() : defaultMacosZipPath;
}
