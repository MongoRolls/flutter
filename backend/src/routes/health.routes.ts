import { Router } from 'express';

import { prisma } from '../config/prisma.js';
import { redis } from '../config/redis.js';

const router = Router();

router.get('/', async (_req, res) => {
  const checks: Record<string, string> = {};
  let healthy = true;

  // PostgreSQL
  try {
    await prisma.$queryRaw`SELECT 1`;
    checks.postgres = 'ok';
  } catch {
    checks.postgres = 'error';
    healthy = false;
  }

  // Redis
  try {
    const pong = await redis.ping();
    checks.redis = pong === 'PONG' ? 'ok' : 'error';
  } catch {
    checks.redis = 'error';
    healthy = false;
  }

  const status = healthy ? 'ok' : 'degraded';
  res.status(healthy ? 200 : 503).json({
    status,
    timestamp: new Date().toISOString(),
    service: 'keleme-backend',
    checks,
  });
});

export default router;
