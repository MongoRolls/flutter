import Redis from 'ioredis';

import { env } from './env.js';
import { logger } from './logger.js';

export const redis = new Redis(env.REDIS_URL, {
  lazyConnect: true,
  maxRetriesPerRequest: 3,
});

redis.on('error', (err) => {
  logger.error({ err }, 'Redis \u8FDE\u63A5\u9519\u8BEF');
});

// 启动时显式连接，尽早发现 Redis 不可用
export async function connectRedis(): Promise<void> {
  try {
    await redis.connect();
    logger.info('Redis \u8FDE\u63A5\u6210\u529F');
  } catch (err) {
    logger.error({ err }, 'Redis \u521D\u59CB\u8FDE\u63A5\u5931\u8D25');
    throw err;
  }
}
