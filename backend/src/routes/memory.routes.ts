import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import * as MemoryService from '../services/memory.service.js';
import type { AuthenticatedRequest } from '../types/index.js';

const router = Router();

const createFactSchema = z.object({
  body: z.object({
    category: z.string().min(1).max(50),
    content: z.string().min(1).max(1000),
    source: z.enum(['chat', 'manual', 'system']).default('chat'),
  }),
});

const querySchema = z.object({
  query: z.object({
    limit: z.coerce.number().int().min(1).max(500).default(100),
    offset: z.coerce.number().int().min(0).default(0),
  }),
});

// GET /api/memory
router.get('/', auth, validate(querySchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const { limit, offset } = req.query as unknown as { limit: number; offset: number };
    const result = await MemoryService.listFacts(userId, { limit, offset });
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// POST /api/memory
router.post('/', auth, validate(createFactSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const fact = await MemoryService.createFact(userId, req.body);
    res.status(201).json(fact);
  } catch (err) {
    next(err);
  }
});

// DELETE /api/memory/:id
router.delete('/:id', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    await MemoryService.deleteFact(userId, req.params.id as string);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

export default router;
