import { Router } from 'express';
import { z } from 'zod';

import { validate } from '../middleware/validate.js';
import { auth } from '../middleware/auth.js';
import { authRateLimit } from '../middleware/rate-limit.js';
import * as AuthService from '../services/auth.service.js';
import type { AuthenticatedRequest } from '../types/index.js';

const router = Router();

// ── Zod Schemas ───────────────────────────────────────────────────────────────

const deviceSchema = z.object({
  body: z.object({
    deviceId: z.string().uuid('deviceId 格式无效，需要 UUID').optional(),
  }),
});

const bindEmailSchema = z.object({
  body: z.object({
    email: z.string().email('邮箱格式不正确'),
    password: z.string().min(8, '密码至少 8 位'),
  }),
});

const loginSchema = z.object({
  body: z.object({
    email: z.string().email('邮箱格式不正确'),
    password: z.string().min(1, '密码不能为空'),
  }),
});

const refreshSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1, 'refreshToken 不能为空'),
  }),
});

const logoutSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1, 'refreshToken 不能为空'),
  }),
});

// ── POST /auth/device ─────────────────────────────────────────────────────────
router.post('/device', authRateLimit, validate(deviceSchema), async (req, res, next) => {
  try {
    const result = await AuthService.deviceLogin(req.body.deviceId);
    res.status(200).json(result);
  } catch (err) {
    next(err);
  }
});

// ── POST /auth/bind-email ─────────────────────────────────────────────────────
router.post('/bind-email', auth, validate(bindEmailSchema), async (req, res, next) => {
  try {
    const { email, password } = req.body;
    await AuthService.bindEmail((req as AuthenticatedRequest).user.id, email, password);
    res.status(200).json({ message: '邮箱绑定成功' });
  } catch (err) {
    next(err);
  }
});

// ── POST /auth/login ──────────────────────────────────────────────────────────
router.post('/login', authRateLimit, validate(loginSchema), async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const tokens = await AuthService.emailLogin(email, password);
    res.status(200).json(tokens);
  } catch (err) {
    next(err);
  }
});

// ── POST /auth/refresh ────────────────────────────────────────────────────────
router.post('/refresh', validate(refreshSchema), async (req, res, next) => {
  try {
    const result = await AuthService.refreshTokens(req.body.refreshToken);
    res.status(200).json(result);
  } catch (err) {
    next(err);
  }
});

// ── POST /auth/logout ─────────────────────────────────────────────────────────
router.post('/logout', auth, validate(logoutSchema), async (req, res, next) => {
  try {
    await AuthService.logout(req.body.refreshToken);
    res.status(200).json({ message: '已登出' });
  } catch (err) {
    next(err);
  }
});

export default router;
