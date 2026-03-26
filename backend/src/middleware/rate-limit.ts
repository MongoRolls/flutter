import type { Request, Response, NextFunction } from 'express';
import { RateLimiterRedis, RateLimiterRes } from 'rate-limiter-flexible';

import { env } from '../config/env.js';
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

// 好友短码查询限流（更严格）：每用户每分钟 N 次 + 每 IP 每分钟 N 次（可从环境变量配置）
const friendLookupPerUserLimiter = new RateLimiterRedis({
  storeClient: redis,
  keyPrefix: 'rl_care_friend_lookup_user',
  points: env.RATE_LIMIT_FRIEND_LOOKUP_USER_PER_MIN,
  duration: 60,
});

const friendLookupPerIpLimiter = new RateLimiterRedis({
  storeClient: redis,
  keyPrefix: 'rl_care_friend_lookup_ip',
  points: env.RATE_LIMIT_FRIEND_LOOKUP_IP_PER_MIN,
  duration: 60,
});

function msBeforeNextFromRejection(rej: unknown): number {
  if (
    typeof rej === 'object' &&
    rej != null &&
    'msBeforeNext' in rej &&
    typeof (rej as RateLimiterRes).msBeforeNext === 'number'
  ) {
    return (rej as RateLimiterRes).msBeforeNext;
  }
  return 60_000;
}

function createRateLimitMiddleware(
  limiter: RateLimiterRedis,
  keyFn: (req: Request) => string,
) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await limiter.consume(keyFn(req));
      res.setHeader('X-RateLimit-Remaining', result.remainingPoints);
      next();
    } catch (rej: unknown) {
      const ms = msBeforeNextFromRejection(rej);
      res.setHeader('Retry-After', String(Math.max(1, Math.ceil(ms / 1000))));
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

// 需放在 auth 之后使用（依赖 userId）；两桶都 consume 成功才放行
export async function friendLookupRateLimit(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const userId = (req as AuthenticatedRequest).user?.id;
  const ip = req.ip ?? 'unknown';
  if (!userId) {
    next();
    return;
  }

  let userConsumed = false;
  try {
    const userRes = await friendLookupPerUserLimiter.consume(userId);
    userConsumed = true;
    const ipRes = await friendLookupPerIpLimiter.consume(ip);
    res.setHeader(
      'X-RateLimit-Remaining',
      Math.min(userRes.remainingPoints, ipRes.remainingPoints),
    );
    next();
  } catch (rej: unknown) {
    if (userConsumed) {
      try {
        await friendLookupPerUserLimiter.reward(userId, 1);
      } catch {
        // ignore
      }
    }
    const ms = msBeforeNextFromRejection(rej);
    res.setHeader('Retry-After', String(Math.max(1, Math.ceil(ms / 1000))));
    next(new TooManyRequestsError());
  }
}
