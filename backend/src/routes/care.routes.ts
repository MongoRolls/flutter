import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { prisma } from '../config/prisma.js';
import type { AuthenticatedRequest } from '../types/index.js';

const router = Router();

const addContactSchema = z.object({
  body: z.object({
    contactId: z.string().min(1),
    nickname: z.string().min(1).max(20),
  }),
});

// GET /api/care/contacts
router.get('/contacts', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const contacts = await prisma.careContact.findMany({
      where: { ownerId: userId },
      include: { contact: { select: { id: true, nickname: true } } },
      orderBy: { createdAt: 'desc' },
    });
    res.json(contacts);
  } catch (err) {
    next(err);
  }
});

// POST /api/care/contacts
router.post('/contacts', auth, validate(addContactSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const { contactId, nickname } = req.body;

    const contact = await prisma.careContact.upsert({
      where: { ownerId_contactId: { ownerId: userId, contactId } },
      update: { nickname },
      create: { ownerId: userId, contactId, nickname },
    });

    res.status(201).json(contact);
  } catch (err) {
    next(err);
  }
});

// DELETE /api/care/contacts/:id
router.delete('/contacts/:id', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const id = req.params.id as string;
    const record = await prisma.careContact.findUnique({ where: { id } });
    if (!record || record.ownerId !== userId) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: '联系人不存在' } });
      return;
    }
    await prisma.careContact.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

export default router;
