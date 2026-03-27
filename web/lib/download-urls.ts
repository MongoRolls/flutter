/**
 * TODO: 在部署环境配置 NEXT_PUBLIC_DOWNLOAD_APK_URL / NEXT_PUBLIC_DOWNLOAD_MACOS_URL
 */
export function getApkUrl(): string | undefined {
  const u = process.env.NEXT_PUBLIC_DOWNLOAD_APK_URL;
  return u && u.trim().length > 0 ? u.trim() : undefined;
}

export function getMacosUrl(): string | undefined {
  const u = process.env.NEXT_PUBLIC_DOWNLOAD_MACOS_URL;
  return u && u.trim().length > 0 ? u.trim() : undefined;
}
