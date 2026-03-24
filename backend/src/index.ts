import 'dotenv/config';

import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { prisma } from './config/prisma.js';
import { redis } from './config/redis.js';
import { app } from './app.js';

const server = app.listen(env.PORT, () => {
  logger.info(`🚀 KeLeME 后端服务已启动，端口 ${env.PORT}，环境 ${env.NODE_ENV}`);
});

// ── 优雅关闭 ──────────────────────────────────────────────────────────────────
async function shutdown(signal: string): Promise<void> {
  logger.info(`收到 ${signal} 信号，正在优雅关闭...`);

  server.close(async () => {
    logger.info('HTTP 服务器已关闭');

    await prisma.$disconnect();
    logger.info('Prisma 连接已断开');

    redis.disconnect();
    logger.info('Redis 连接已断开');

    process.exit(0);
  });

  // 超时强制退出
  setTimeout(() => {
    logger.error('优雅关闭超时，强制退出');
    process.exit(1);
  }, 10_000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
