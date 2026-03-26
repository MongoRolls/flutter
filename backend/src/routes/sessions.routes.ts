import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import * as SessionService from '../services/session.service.js';
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
    const summaries = await SessionService.listSummaries(userId);
    res.json(summaries);
  } catch (err) {
    next(err);
  }
});

// POST /api/sessions
router.post('/', auth, validate(createSummarySchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const record = await SessionService.createSummary(userId, req.body.summary);
    res.status(201).json(record);
  } catch (err) {
    next(err);
  }
});

export default router;
