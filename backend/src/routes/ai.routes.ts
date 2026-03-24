import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { aiRateLimit } from '../middleware/rate-limit.js';
import { validate } from '../middleware/validate.js';
import { env } from '../config/env.js';
import { logger } from '../config/logger.js';

const router = Router();

const chatSchema = z.object({
  body: z.object({
    messages: z.array(z.object({
      role: z.enum(['system', 'user', 'assistant', 'tool']),
      content: z.string().nullable().optional(),
      tool_calls: z.array(z.unknown()).optional(),
      tool_call_id: z.string().optional(),
    })),
    tools: z.array(z.unknown()).optional(),
    temperature: z.number().min(0).max(2).default(0.7),
    max_tokens: z.number().int().min(1).max(8192).default(2048),
    stream: z.boolean().default(true),
  }),
});

// POST /api/ai/chat — SSE proxy to DeepSeek
router.post('/chat', auth, aiRateLimit, validate(chatSchema), async (req, res, next) => {
  try {
    const { messages, tools, temperature, max_tokens, stream } = req.body;

    const requestBody: Record<string, unknown> = {
      model: 'deepseek-chat',
      messages,
      temperature,
      max_tokens,
      stream,
    };
    if (tools && (tools as unknown[]).length > 0) {
      requestBody['tools'] = tools;
      requestBody['tool_choice'] = 'auto';
    }

    const upstream = await fetch('https://api.deepseek.com/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.DEEPSEEK_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody),
    });

    if (!upstream.ok) {
      const errBody = await upstream.text();
      logger.error({ status: upstream.status, body: errBody }, 'DeepSeek upstream error');
      res.status(upstream.status).json({
        error: { code: 'UPSTREAM_ERROR', message: `DeepSeek API ${upstream.status}` },
      });
      return;
    }

    if (stream && upstream.body) {
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');

      const reader = upstream.body.getReader();
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          res.write(value);
        }
      } catch (e) {
        logger.error({ err: e }, 'SSE stream error');
      } finally {
        res.end();
      }
    } else {
      const data = await upstream.json();
      res.json(data);
    }
  } catch (err) {
    next(err);
  }
});

export default router;
