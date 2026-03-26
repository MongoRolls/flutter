import 'dotenv/config';

import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { prisma } from './config/prisma.js';
import { redis, connectRedis } from './config/redis.js';
import { app } from './app.js';

async function main(): Promise<void> {
  // 启动前验证 Redis 连接
  await connectRedis();

  const server = app.listen(env.PORT, () => {
    logger.info(`KeLeME \u540E\u7AEF\u670D\u52A1\u5DF2\u542F\u52A8\uFF0C\u7AEF\u53E3 ${env.PORT}\uFF0C\u73AF\u5883 ${env.NODE_ENV}`);
  });

  // ── \u4F18\u96C5\u5173\u95ED ──────────────────────────────────────────────────────────────────
  async function shutdown(signal: string): Promise<void> {
    logger.info(`\u6536\u5230 ${signal} \u4FE1\u53F7\uFF0C\u6B63\u5728\u4F18\u96C5\u5173\u95ED...`);

    server.close(async () => {
      logger.info('HTTP \u670D\u52A1\u5668\u5DF2\u5173\u95ED');

      await prisma.$disconnect();
      logger.info('Prisma \u8FDE\u63A5\u5DF2\u65AD\u5F00');

      redis.disconnect();
      logger.info('Redis \u8FDE\u63A5\u5DF2\u65AD\u5F00');

      process.exit(0);
    });

    // \u8D85\u65F6\u5F3A\u5236\u9000\u51FA
    setTimeout(() => {
      logger.error('\u4F18\u96C5\u5173\u95ED\u8D85\u65F6\uFF0C\u5F3A\u5236\u9000\u51FA');
      process.exit(1);
    }, 10_000);
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

main().catch((err) => {
  logger.fatal({ err }, '\u670D\u52A1\u542F\u52A8\u5931\u8D25');
  process.exit(1);
});
