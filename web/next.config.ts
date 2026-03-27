import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* React Compiler 在部分环境下会影响客户端事件 / console，主题切换需稳定时保持关闭 */
  reactCompiler: false,
  devIndicators: false,
};

export default nextConfig;
