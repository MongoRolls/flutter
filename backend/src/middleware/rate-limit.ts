import type { Request, Response, NextFunction } from 'express';
import { RateLimiterRedis } from 'rate-limiter-flexible';

import { redis } from '../config/redis.js';
import { TooManyRequestsError } from '../utils/errors.js';
import type { AuthenticatedRequest } from '../types/index.js';

// 通用 API 限流：每用户每分钟 100 次
const generalLimiter = new RateLimiterRedis({
  storeClient: redis,
  keyPrefix: 'rl_general',
  points: 100,
  duration: 60,
});

// AI 接口限流：每用户每分钟 10 次
const aiLimiter = new RateLimiterRedis({
  storeClient: redis,
  keyPrefix: 'rl_ai',
  points: 10,
  duration: 60,
});

// Auth 接口限流：每 IP 每分钟 5 次
const authLimiter = new RateLimiterRedis({
  storeClient: redis,
  keyPrefix: 'rl_auth',
  points: 5,
  duration: 60,
});

function createRateLimitMiddleware(
  limiter: RateLimiterRedis,
  keyFn: (req: Request) => string,
) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await limiter.consume(keyFn(req));
      res.setHeader('X-RateLimit-Remaining', result.remainingPoints);
      next();
    } catch {
      res.setHeader('Retry-After', '60');
      next(new TooManyRequestsError());
    }
  };
}

export const generalRateLimit = createRateLimitMiddleware(
  generalLimiter,
  (req) => (req as AuthenticatedRequest).user?.id ?? req.ip ?? 'unknown',
);

export const aiRateLimit = createRateLimitMiddleware(
  aiLimiter,
  (req) => (req as AuthenticatedRequest).user?.id ?? req.ip ?? 'unknown',
);

export const authRateLimit = createRateLimitMiddleware(
  authLimiter,
  (req) => req.ip ?? 'unknown',
);
