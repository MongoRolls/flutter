import type { Request, Response, NextFunction } from 'express';

import { logger } from '../config/logger.js';
import { AppError } from '../utils/errors.js';

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction,
): void {
  if (err instanceof AppError) {
    // 已知业务错误
    res.status(err.statusCode).json({
      error: {
        code: err.code ?? 'ERROR',
        message: err.message,
      },
    });
    return;
  }

  // 未知错误，记录完整堆栈但不暴露给客户端
  logger.error({ err }, '未处理的服务器错误');

  res.status(500).json({
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: '服务器内部错误，请稍后重试',
    },
  });
}
