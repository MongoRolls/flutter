import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { prisma } from '../config/prisma.js';
import type { AuthenticatedRequest } from '../types/index.js';

const router = Router();

const createFactSchema = z.object({
  body: z.object({
    category: z.string().min(1).max(50),
    content: z.string().min(1).max(1000),
    source: z.enum(['chat', 'manual', 'system']).default('chat'),
  }),
});

// GET /api/memory
router.get('/', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const facts = await prisma.memoryFact.findMany({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
    });
    res.json(facts);
  } catch (err) {
    next(err);
  }
});

// POST /api/memory
router.post('/', auth, validate(createFactSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const { category, content, source } = req.body;

    const fact = await prisma.memoryFact.create({
      data: { userId, category, content, source: source ?? 'chat' },
    });

    res.status(201).json(fact);
  } catch (err) {
    next(err);
  }
});

// DELETE /api/memory/:id
router.delete('/:id', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const id = req.params.id as string;
    const fact = await prisma.memoryFact.findUnique({ where: { id } });
    if (!fact || fact.userId !== userId) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: '记忆不存在' } });
      return;
    }
    await prisma.memoryFact.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

export default router;
