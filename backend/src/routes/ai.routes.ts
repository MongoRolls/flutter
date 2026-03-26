import { Router } from 'express';
import { z } from 'zod';

import { auth } from '../middleware/auth.js';
import { aiRateLimit } from '../middleware/rate-limit.js';
import { validate } from '../middleware/validate.js';
import { env } from '../config/env.js';
import { logger } from '../config/logger.js';

const router = Router();

const messageSchema = z.object({
  role: z.enum(['system', 'user', 'assistant', 'tool']),
  content: z.string().nullable().optional(),
  tool_calls: z.array(z.unknown()).optional(),
  tool_call_id: z.string().optional(),
});

const chatSchema = z.object({
  body: z.object({
    messages: z.array(messageSchema),
    tools: z.array(z.unknown()).optional(),
    temperature: z.number().min(0).max(2).default(0.7),
    max_tokens: z.number().int().min(1).max(8192).default(2048),
    stream: z.boolean().default(true),
  }),
});

// 清洗 messages，仅保留合法字段，剥离客户端可能注入的敏感键
function sanitizeMessages(
  messages: Array<Record<string, unknown>>,
): Array<Record<string, unknown>> {
  return messages.map((msg) => {
    const clean: Record<string, unknown> = {
      role: msg.role,
      content: msg.content ?? null,
    };
    if (msg.tool_calls) clean.tool_calls = msg.tool_calls;
    if (msg.tool_call_id) clean.tool_call_id = msg.tool_call_id;
    return clean;
  });
}

// POST /api/ai/chat — SSE proxy to DeepSeek
router.post('/chat', auth, aiRateLimit, validate(chatSchema), async (req, res, next) => {
  const controller = new AbortController();

  // 客户端断开时中止上游请求，避免浪费 token
  req.on('close', () => {
    if (!res.writableEnded) {
      controller.abort();
      logger.info('客户端断开，已中止上游 DeepSeek 请求');
    }
  });

  try {
    const { messages, tools, temperature, max_tokens, stream } = req.body;

    const cleanMessages = sanitizeMessages(messages);

    const requestBody: Record<string, unknown> = {
      model: 'deepseek-chat',
      messages: cleanMessages,
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
      signal: controller.signal,
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
      res.flushHeaders();

      const reader = upstream.body.getReader();
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          res.write(value);
        }
      } catch (e) {
        if ((e as Error).name !== 'AbortError') {
          logger.error({ err: e }, 'SSE stream error');
        }
      } finally {
        res.end();
      }
    } else {
      const data = await upstream.json();
      res.json(data);
    }
  } catch (err) {
    if ((err as Error).name === 'AbortError') {
      if (!res.headersSent) res.end();
      return;
    }
    next(err);
  }
});

export default router;
