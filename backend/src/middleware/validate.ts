import type { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';

import { ValidationError } from '../utils/errors.js';

export function validate(schema: ZodSchema) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      const result = schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });

      // 将经过校验/转换后的值写回 req
      if (result.body !== undefined) req.body = result.body;
      if (result.query !== undefined) req.query = result.query;
      if (result.params !== undefined) req.params = result.params;

      next();
    } catch (err) {
      if (err instanceof ZodError) {
        const messages = err.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join('; ');
        next(new ValidationError(messages));
      } else {
        next(err);
      }
    }
  };
}
