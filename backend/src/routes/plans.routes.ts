import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { prisma } from '../config/prisma.js';
import type { AuthenticatedRequest } from '../types/index.js';

const router = Router();

const upsertPlanSchema = z.object({
  body: z.object({
    date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, '日期格式需为 YYYY-MM-DD'),
    planJson: z.record(z.unknown()),
  }),
});

// GET /api/plans?date=YYYY-MM-DD
router.get('/', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const date = req.query.date as string;

    if (!date) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: '缺少 date 参数' } });
      return;
    }

    const plan = await prisma.todayPlan.findUnique({
      where: { userId_date: { userId, date: new Date(date) } },
    });

    res.json(plan ?? null);
  } catch (err) {
    next(err);
  }
});

// POST /api/plans
router.post('/', auth, validate(upsertPlanSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const { date, planJson } = req.body;

    const plan = await prisma.todayPlan.upsert({
      where: { userId_date: { userId, date: new Date(date) } },
      update: { planJson },
      create: { userId, date: new Date(date), planJson },
    });

    res.status(201).json(plan);
  } catch (err) {
    next(err);
  }
});

export default router;
