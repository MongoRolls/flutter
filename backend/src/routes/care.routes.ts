import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import {
  friendLookupRateLimit,
  peerRemindRateLimit,
} from '../middleware/rate-limit.js';
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

const lookupFriendCodeSchema = z.object({
  query: z.object({
    code: z.string().min(6).max(6),
  }),
});

const dateRegex = /^\d{4}-\d{2}-\d{2}$/;

const peersHydrationSchema = z.object({
  query: z.object({
    date: z.string().regex(dateRegex),
    tzOffset: z.coerce.number().int().min(-720).max(840).default(0),
  }),
});

const peerRemindSchema = z.object({
  body: z.object({
    contactId: z.string().min(1),
    templateId: z.number().int().min(1).max(4),
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

// GET /api/care/friend-code
router.get('/friend-code', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const friendCode = await CareService.getOrCreateFriendCode(userId);
    res.json({ friendCode });
  } catch (err) {
    next(err);
  }
});

// POST /api/care/friend-code/rotate
router.post('/friend-code/rotate', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const friendCode = await CareService.rotateFriendCode(userId);
    res.json({ friendCode });
  } catch (err) {
    next(err);
  }
});

// GET /api/care/friend-lookup?code=XXXXXX
router.get(
  '/friend-lookup',
  auth,
  friendLookupRateLimit,
  validate(lookupFriendCodeSchema),
  async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const code = req.query.code as string;
    const result = await CareService.lookupByFriendCode(userId, code);
    res.json(result);
  } catch (err) {
    next(err);
  }
  },
);

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

// GET /api/care/peers/hydration?date=YYYY-MM-DD&tzOffset=
router.get(
  '/peers/hydration',
  auth,
  validate(peersHydrationSchema),
  async (req, res, next) => {
    try {
      const userId = (req as AuthenticatedRequest).user.id;
      const date = req.query.date as string;
      const tzOffset = Number(req.query.tzOffset ?? 0);
      const rows = await CareService.getPeersHydration(userId, date, tzOffset);
      res.json(rows);
    } catch (err) {
      next(err);
    }
  },
);

// POST /api/care/remind  { contactId, templateId }
router.post(
  '/remind',
  auth,
  validate(peerRemindSchema),
  peerRemindRateLimit,
  async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const { contactId, templateId } = req.body as {
      contactId: string;
      templateId: number;
    };
    const row = await CareService.sendPeerRemind(userId, contactId, templateId);
    res.status(201).json(row);
  } catch (err) {
    next(err);
  }
  },
);

export default router;
