import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { friendLookupRateLimit } from '../middleware/rate-limit.js';
import { validate } from '../middleware/validate.js';
import * as ChallengesService from '../services/challenges.service.js';
import type { AuthenticatedRequest } from '../types/index.js';

const router = Router();

const createSchema = z
  .object({
    body: z.object({
      title: z.string().min(1).max(80),
      goalType: z.enum(['individual_daily', 'team_total']).optional(),
      goalValue: z.number().int().positive(),
      periodStart: z.string().min(1),
      periodEnd: z.string().min(1),
    }),
  })
  .superRefine((data, ctx) => {
    const a = new Date(data.body.periodStart);
    const b = new Date(data.body.periodEnd);
    if (Number.isNaN(a.getTime()) || Number.isNaN(b.getTime())) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: '日期格式无效',
        path: ['body', 'periodStart'],
      });
      return;
    }
    if (b <= a) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: '结束时间必须晚于开始时间',
        path: ['body', 'periodEnd'],
      });
    }
  });

const joinSchema = z.object({
  body: z.object({
    inviteCode: z
      .string()
      .length(6)
      .regex(/^[A-Za-z0-9]{6}$/, '邀请码应为 6 位字母或数字'),
  }),
});

const challengeIdParamsSchema = z.object({
  params: z.object({
    id: z.string().cuid(),
  }),
});

const mineQuerySchema = z.object({
  query: z.object({
    localDate: z
      .string()
      .regex(/^\d{4}-\d{2}-\d{2}$/)
      .optional(),
    tzOffset: z.coerce.number().int().min(-720).max(840).optional(),
  }),
});

// POST /api/challenges
router.post('/', auth, validate(createSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const body = req.body as z.infer<typeof createSchema>['body'];
    const challenge = await ChallengesService.createChallenge(userId, {
      title: body.title,
      goalType: body.goalType,
      goalValue: body.goalValue,
      periodStart: body.periodStart,
      periodEnd: body.periodEnd,
    });
    res.status(201).json({
      id: challenge.id,
      title: challenge.title,
      goalType: challenge.goalType,
      goalValue: challenge.goalValue,
      periodStart: challenge.periodStart.toISOString(),
      periodEnd: challenge.periodEnd.toISOString(),
      status: challenge.status,
      inviteCode: challenge.inviteCode,
      createdAt: challenge.createdAt.toISOString(),
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/challenges/join
router.post(
  '/join',
  auth,
  friendLookupRateLimit,
  validate(joinSchema),
  async (req, res, next) => {
    try {
      const userId = (req as AuthenticatedRequest).user.id;
      const { inviteCode } = req.body as z.infer<typeof joinSchema>['body'];
      const challenge = await ChallengesService.joinChallenge(userId, inviteCode);
      res.status(200).json({
        challengeId: challenge.id,
        title: challenge.title,
        status: challenge.status,
      });
    } catch (err) {
      next(err);
    }
  },
);

// GET /api/challenges/mine
router.get('/mine', auth, validate(mineQuerySchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const q = req.query as z.infer<typeof mineQuerySchema>['query'];
    const result = await ChallengesService.getMyChallengesFull(
      userId,
      q.localDate,
      q.tzOffset,
    );
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/challenges/:id
router.get('/:id', auth, validate(challengeIdParamsSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const detail = await ChallengesService.getChallengeDetail(userId, req.params.id as string);
    res.json(detail);
  } catch (err) {
    next(err);
  }
});

// POST /api/challenges/:id/leave
router.post('/:id/leave', auth, validate(challengeIdParamsSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    await ChallengesService.leaveChallenge(userId, req.params.id as string);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// POST /api/challenges/:id/result-ack
router.post('/:id/result-ack', auth, validate(challengeIdParamsSchema), async (req, res, next) => {
  try {
    const userId = (req as AuthenticatedRequest).user.id;
    const result = await ChallengesService.ackResult(userId, req.params.id as string);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

export default router;
