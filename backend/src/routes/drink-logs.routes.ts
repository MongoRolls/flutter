import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import * as DrinkLogService from '../services/drink-log.service.js';
import type { AuthenticatedRequest } from '../types/index.js';

const router = Router();

const createLogSchema = z.object({
  body: z.object({
    ml: z.number().int().min(1).max(5000),
    icon: z.string().default('\u{1F4A7}'),
    description: z.string().default('喝水'),
    loggedAt: z.string().datetime().optional(),
  }),
});

const bulkSyncSchema = z.object({
  body: z.object({
    logs: z.array(z.object({
      localId: z.string(),
      ml: z.number().int().min(1).max(5000),
      icon: z.string().default('\u{1F4A7}'),
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
    tzOffset: z.coerce.number().int().min(-720).max(840).default(0),
  }),
});

// GET /api/drink-logs
router.get('/', auth, validate(querySchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const { date, startDate, endDate, limit, tzOffset } = req.query as unknown as {
      date?: string; startDate?: string; endDate?: string; limit: number; tzOffset: number;
    };

    const result = await DrinkLogService.queryLogs(userId, {
      date, startDate, endDate, limit, tzOffsetMin: tzOffset,
    });
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// POST /api/drink-logs
router.post('/', auth, validate(createLogSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const log = await DrinkLogService.createLog(userId, req.body);
    res.status(201).json(log);
  } catch (err) {
    next(err);
  }
});

// POST /api/drink-logs/bulk-sync
router.post('/bulk-sync', auth, validate(bulkSyncSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const result = await DrinkLogService.bulkSync(userId, req.body.logs);
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
});

// DELETE /api/drink-logs/:id
router.delete('/:id', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    await DrinkLogService.deleteLog(userId, req.params.id as string);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

export default router;
