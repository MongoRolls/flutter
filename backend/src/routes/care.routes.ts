import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import * as CareService from '../services/care.service.js';
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
    const contacts = await CareService.listContacts(userId);
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
    const contact = await CareService.upsertContact(userId, contactId, nickname);
    res.status(201).json(contact);
  } catch (err) {
    next(err);
  }
});

// DELETE /api/care/contacts/:id
router.delete('/contacts/:id', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    await CareService.deleteContact(userId, req.params.id as string);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

export default router;
