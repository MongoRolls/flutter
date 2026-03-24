import pino from 'pino';

import { env } from './env.js';

export const logger = pino(
  {
    level: env.NODE_ENV === 'test' ? 'silent' : 'info',
    redact: {
      paths: [
        'req.headers.authorization',
        'req.body.password',
        'req.body.passwordHash',
      ],
      censor: '[REDACTED]',
    },
  },
  env.NODE_ENV === 'development'
    ? pino.transport({ target: 'pino-pretty', options: { colorize: true } })
    : undefined,
);
