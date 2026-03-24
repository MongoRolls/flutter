import { randomUUID } from 'crypto';

import { prisma } from '../config/prisma.js';
import { redis } from '../config/redis.js';
import { hashPassword, verifyPassword } from '../utils/password.js';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../utils/jwt.js';
import { ConflictError, UnauthorizedError } from '../utils/errors.js';

// Refresh token 在 Redis 中的 key 前缀，黑名单用 "rt:bl:{token}"
const RT_BLACKLIST_PREFIX = 'rt:bl:';
// 7 天对应的秒数
const REFRESH_TTL_SECONDS = 7 * 24 * 60 * 60;

function tokenPair(userId: string, email: string | null) {
  return {
    accessToken: signAccessToken({ id: userId, email }),
    refreshToken: signRefreshToken({ id: userId }),
  };
}

// ── 设备匿名登录 ──────────────────────────────────────────────────────────────

export async function deviceLogin(deviceId?: string): Promise<{
  accessToken: string;
  refreshToken: string;
  deviceId: string;
  isNewUser: boolean;
}> {
  const resolvedDeviceId = deviceId ?? randomUUID();
  let isNewUser = false;

  // upsert 保证同一 deviceId 并发调用也只创建一条记录
  const user = await prisma.user.upsert({
    where: { deviceId: resolvedDeviceId },
    update: {},
    create: { deviceId: resolvedDeviceId },
    select: { id: true, email: true, deviceId: true },
  });

  // 如果 updatedAt === createdAt 可判断是新用户，
  // 但 upsert 没有简单区分方法，改用"用 createAt 与 now 差值"
  // 简单做法：查一次记录是否在最近 2 秒内创建
  const fresh = await prisma.user.findUnique({
    where: { id: user.id },
    select: { createdAt: true },
  });
  isNewUser = fresh !== null && Date.now() - fresh.createdAt.getTime() < 2000;

  const { accessToken, refreshToken } = tokenPair(user.id, user.email);
  return { accessToken, refreshToken, deviceId: resolvedDeviceId, isNewUser };
}

// ── 绑定邮箱 ──────────────────────────────────────────────────────────────────

export async function bindEmail(
  userId: string,
  email: string,
  password: string,
): Promise<void> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { email: true },
  });

  // 幂等：已绑定该邮箱则直接返回
  if (user?.email === email) return;

  // 邮箱被其他用户占用
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) throw new ConflictError('该邮箱已被绑定');

  const passwordHash = await hashPassword(password);
  await prisma.user.update({
    where: { id: userId },
    data: { email, passwordHash },
  });
}

// ── 邮箱密码登录 ──────────────────────────────────────────────────────────────

export async function emailLogin(
  email: string,
  password: string,
): Promise<{ accessToken: string; refreshToken: string }> {
  const user = await prisma.user.findUnique({
    where: { email },
    select: { id: true, email: true, passwordHash: true },
  });

  // 统一返回 401，不泄露邮箱是否存在
  if (!user || !user.passwordHash) {
    throw new UnauthorizedError('邮箱或密码错误');
  }

  const valid = await verifyPassword(password, user.passwordHash);
  if (!valid) throw new UnauthorizedError('邮箱或密码错误');

  return tokenPair(user.id, user.email);
}

// ── 刷新 Token ────────────────────────────────────────────────────────────────

export async function refreshTokens(
  refreshToken: string,
): Promise<{ accessToken: string }> {
  // 验证签名和过期
  let payload: { id: string };
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw new UnauthorizedError('Refresh token 无效或已过期');
  }

  // 黑名单检查
  const blacklisted = await redis.get(`${RT_BLACKLIST_PREFIX}${refreshToken}`);
  if (blacklisted) throw new UnauthorizedError('Token 已失效');

  // 用户还存在？
  const user = await prisma.user.findUnique({
    where: { id: payload.id },
    select: { id: true, email: true },
  });
  if (!user) throw new UnauthorizedError('账户不存在');

  return { accessToken: signAccessToken({ id: user.id, email: user.email }) };
}

// ── 登出 ──────────────────────────────────────────────────────────────────────

export async function logout(refreshToken: string): Promise<void> {
  // 尝试解析剩余有效期，用于设置 Redis TTL（过期后自动清理）
  let ttl = REFRESH_TTL_SECONDS;
  try {
    const payload = verifyRefreshToken(refreshToken) as { exp?: number };
    if (payload.exp) {
      ttl = Math.max(payload.exp - Math.floor(Date.now() / 1000), 1);
    }
  } catch {
    // 已过期的 token 加入黑名单意义不大，但无害
  }

  await redis.set(`${RT_BLACKLIST_PREFIX}${refreshToken}`, '1', 'EX', ttl);
}
