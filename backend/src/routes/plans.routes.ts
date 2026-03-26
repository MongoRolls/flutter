import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import * as PlanService from '../services/plan.service.js';
import type { AuthenticatedRequest } from '../types/index.js';

const router = Router();

const upsertPlanSchema = z.object({
  body: z.object({
    date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, '\u65E5\u671F\u683C\u5F0F\u9700\u4E3A YYYY-MM-DD'),
    planJson: z.record(z.unknown()),
  }),
});

// GET /api/plans?date=YYYY-MM-DD
router.get('/', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const date = req.query.date as string;

    if (!date) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: '\u7F3A\u5C11 date \u53C2\u6570' } });
      return;
    }

    const plan = await PlanService.getPlan(userId, date);
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
    const plan = await PlanService.upsertPlan(userId, date, planJson);
    res.status(201).json(plan);
  } catch (err) {
    next(err);
  }
});

export default router;
