import Redis from 'ioredis';

import { env } from './env.js';
import { logger } from './logger.js';

export const redis = new Redis(env.REDIS_URL, {
  lazyConnect: true,
  maxRetriesPerRequest: 3,
});

redis.on('error', (err) => {
  logger.error({ err }, 'Redis 连接错误');
});

// 启动时显式连接，尽早发现 Redis 不可用
export async function connectRedis(): Promise<void> {
  try {
    await redis.connect();
    logger.info('Redis 连接成功');
  } catch (err) {
    logger.error({ err }, 'Redis 初始连接失败');
    throw err;
  }
}
