import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { prisma } from '../config/prisma.js';
import type { AuthenticatedRequest } from '../types/index.js';

const router = Router();

const createLogSchema = z.object({
  body: z.object({
    ml: z.number().int().min(1).max(5000),
    icon: z.string().default('💧'),
    description: z.string().default('喝水'),
    loggedAt: z.string().datetime().optional(),
  }),
});

const bulkSyncSchema = z.object({
  body: z.object({
    logs: z.array(z.object({
      localId: z.string(),
      ml: z.number().int().min(1).max(5000),
      icon: z.string().default('💧'),
      description: z.string().default('喝水'),
      loggedAt: z.string().datetime(),
    })).max(500),
  }),
});

const dateRegex = /^\d{4}-\d{2}-\d{2}$/;

const querySchema = z.object({
  query: z.object({
    date: z.string().regex(dateRegex).optional(),
    startDate: z.string().regex(dateRegex).optional(),
    endDate: z.string().regex(dateRegex).optional(),
    limit: z.coerce.number().int().min(1).max(500).default(100),
  }),
});

// GET /api/drink-logs
router.get('/', auth, validate(querySchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const { date, startDate, endDate, limit } = req.query as unknown as { date?: string; startDate?: string; endDate?: string; limit: number };

    const loggedAtFilter: { gte?: Date; lt?: Date; lte?: Date } = {};
    if (date) {
      loggedAtFilter.gte = new Date(date);
      loggedAtFilter.lt = new Date(new Date(date).setDate(new Date(date).getDate() + 1));
    } else if (startDate || endDate) {
      if (startDate) loggedAtFilter.gte = new Date(startDate);
      if (endDate) loggedAtFilter.lte = new Date(endDate);
    }

    const logs = await prisma.drinkLog.findMany({
      where: { userId, ...(Object.keys(loggedAtFilter).length ? { loggedAt: loggedAtFilter } : {}) },
      orderBy: { loggedAt: 'desc' },
      take: limit,
    });

    const totalMl = logs.reduce((sum, l) => sum + l.ml, 0);
    res.json({ logs, totalMl, count: logs.length });
  } catch (err) {
    next(err);
  }
});

// POST /api/drink-logs
router.post('/', auth, validate(createLogSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const { ml, icon, description, loggedAt } = req.body;

    const log = await prisma.drinkLog.create({
      data: {
        userId,
        ml,
        icon: icon ?? '💧',
        description: description ?? '喝水',
        loggedAt: loggedAt ? new Date(loggedAt) : new Date(),
        syncedAt: new Date(),
      },
    });

    res.status(201).json(log);
  } catch (err) {
    next(err);
  }
});

// POST /api/drink-logs/bulk-sync
router.post('/bulk-sync', auth, validate(bulkSyncSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const { logs } = req.body;
    const now = new Date();

    const created = await prisma.$transaction(
      (logs as Array<{ localId: string; ml: number; icon: string; description: string; loggedAt: string }>).map((l) =>
        prisma.drinkLog.create({
          data: {
            userId,
            ml: l.ml,
            icon: l.icon ?? '💧',
            description: l.description ?? '喝水',
            loggedAt: new Date(l.loggedAt),
            syncedAt: now,
          },
        }),
      ),
    );

    const result = created.map((c, i) => ({ localId: (logs as Array<{ localId: string }>)[i].localId, serverId: c.id }));
    res.status(201).json({ synced: result.length, idMap: result });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/drink-logs/:id
router.delete('/:id', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const id = req.params.id as string;
    const log = await prisma.drinkLog.findUnique({ where: { id } });
    if (!log || log.userId !== userId) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: '记录不存在' } });
      return;
    }
    await prisma.drinkLog.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

export default router;
