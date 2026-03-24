import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { prisma } from '../config/prisma.js';
import type { AuthenticatedRequest } from '../types/index.js';

const router = Router();

const createSummarySchema = z.object({
  body: z.object({
    summary: z.string().min(1).max(2000),
  }),
});

// GET /api/sessions
router.get('/', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const summaries = await prisma.sessionSummary.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    res.json(summaries);
  } catch (err) {
    next(err);
  }
});

// POST /api/sessions
router.post('/', auth, validate(createSummarySchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const { summary } = req.body;

    const record = await prisma.sessionSummary.create({
      data: { userId, summary },
    });

    res.status(201).json(record);
  } catch (err) {
    next(err);
  }
});

export default router;
