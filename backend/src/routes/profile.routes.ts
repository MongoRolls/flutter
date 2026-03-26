import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import * as ProfileService from '../services/profile.service.js';
import type { AuthenticatedRequest } from '../types/index.js';

const router = Router();

const updateProfileSchema = z.object({
  body: z.object({
    dailyGoalMl: z.number().int().min(500).max(10000).optional(),
    wakeTimeHour: z.number().int().min(0).max(23).optional(),
    wakeTimeMinute: z.number().int().min(0).max(59).optional(),
    bedTimeHour: z.number().int().min(0).max(23).optional(),
    bedTimeMinute: z.number().int().min(0).max(59).optional(),
    reminderIntervalMin: z.number().int().min(15).max(240).optional(),
    reminderStyle: z.enum(['gentle', 'lively', 'serious']).optional(),
    notificationsEnabled: z.boolean().optional(),
    weightKg: z.number().min(20).max(300).optional(),
    activityLevel: z.enum(['sedentary', 'light', 'moderate', 'active', 'very_active']).optional(),
    nickname: z.string().min(1).max(20).optional(),
  }),
});

// GET /api/profile
router.get('/', auth, async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const result = await ProfileService.getProfile(userId);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// PUT /api/profile
router.put('/', auth, validate(updateProfileSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const result = await ProfileService.updateProfile(userId, req.body);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

export default router;
