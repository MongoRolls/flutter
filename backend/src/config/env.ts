import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  DEEPSEEK_API_KEY: z.string().startsWith('sk-'),
  CORS_ORIGIN: z.string().default('*'),
  // 限流配置（好友短码查询）
  // 好友短码查询（防枚举）；开发/连点「添加」时过严易 429，默认略高于「每分钟 1 次尝试」
  RATE_LIMIT_FRIEND_LOOKUP_USER_PER_MIN: z.coerce.number().default(30),
  RATE_LIMIT_FRIEND_LOOKUP_IP_PER_MIN: z.coerce.number().default(40),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ 环境变量校验失败，请检查 .env 配置：');
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
