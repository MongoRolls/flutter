import type { Request, Response, NextFunction } from 'express';

import { UnauthorizedError } from '../utils/errors.js';
import { verifyAccessToken } from '../utils/jwt.js';
import type { AuthenticatedRequest } from '../types/index.js';

export function auth(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    next(new UnauthorizedError('缺少 Authorization 请求头'));
    return;
  }

  const token = authHeader.slice(7);

  try {
    const payload = verifyAccessToken(token);
    (req as AuthenticatedRequest).user = { id: payload.id, email: payload.email };
    next();
  } catch {
    next(new UnauthorizedError('Token 无效或已过期'));
  }
}
