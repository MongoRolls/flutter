import type { Request } from 'express';

// 扩展 Express Request，注入已认证的用户信息
export interface AuthenticatedRequest extends Request {
  user: {
    id: string;
    email: string | null;
  };
}
