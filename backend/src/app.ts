import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import pinoHttp from 'pino-http';

import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { errorHandler } from './middleware/error-handler.js';
import { generalRateLimit } from './middleware/rate-limit.js';
import healthRouter from './routes/health.routes.js';
import authRouter from './routes/auth.routes.js';
import profileRouter from './routes/profile.routes.js';
import drinkLogsRouter from './routes/drink-logs.routes.js';
import aiRouter from './routes/ai.routes.js';
import careRouter from './routes/care.routes.js';
import challengesRouter from './routes/challenges.routes.js';

export const app = express();

// ── 安全与基础中间件 ──────────────────────────────────────────────────────────
app.use(helmet());
app.use(
  cors({
    origin: env.NODE_ENV === 'production' ? env.CORS_ORIGIN.split(',') : '*',
    credentials: true,
  }),
);
app.use(pinoHttp({ logger }));
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

// ── 路由 ──────────────────────────────────────────────────────────────────────
app.use('/health', healthRouter);
app.use('/auth', authRouter);

// /api/* 路由统一应用通用限流（100 次/分/用户）
app.use('/api', generalRateLimit);
app.use('/api/profile', profileRouter);
app.use('/api/drink-logs', drinkLogsRouter);
app.use('/api/ai', aiRouter);
app.use('/api/care', careRouter);
app.use('/api/challenges', challengesRouter);

// ── 全局错误处理（必须在所有路由之后）────────────────────────────────────────
app.use(errorHandler);
