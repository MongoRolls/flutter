import { randomInt } from 'crypto';

import { Prisma } from '@prisma/client';

import { prisma } from '../config/prisma.js';
import { NotFoundError, ValidationError } from '../utils/errors.js';

const FRIEND_CODE_LENGTH = 6;
const FRIEND_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export async function listContacts(userId: string) {
  return prisma.careContact.findMany({
    where: { ownerId: userId },
    include: { contact: { select: { id: true, nickname: true } } },
    orderBy: { createdAt: 'desc' },
  });
}

export async function upsertContact(
  userId: string,
  contactId: string,
  nickname: string,
) {
  if (userId === contactId) {
    throw new ValidationError('不能添加自己为关怀联系人');
  }

  const target = await prisma.user.findUnique({
    where: { id: contactId },
    select: { id: true },
  });
  if (!target) {
    throw new NotFoundError('目标用户');
  }

  return prisma.careContact.upsert({
    where: { ownerId_contactId: { ownerId: userId, contactId } },
    update: { nickname },
    create: { ownerId: userId, contactId, nickname },
  });
}

function normalizeFriendCode(code: string): string {
  return code.trim().replaceAll(' ', '').toUpperCase();
}

function createCandidateFriendCode(): string {
  let code = '';
  for (let i = 0; i < FRIEND_CODE_LENGTH; i++) {
    const idx = randomInt(0, FRIEND_CODE_ALPHABET.length);
    code += FRIEND_CODE_ALPHABET[idx] as string;
  }
  return code;
}

async function generateUniqueFriendCode(excludeCode?: string): Promise<string> {
  for (let i = 0; i < 12; i++) {
    const candidate = createCandidateFriendCode();
    if (excludeCode && candidate === excludeCode) continue;
    const exists = await prisma.user.findUnique({
      where: { friendCode: candidate },
      select: { id: true },
    });
    if (!exists) return candidate;
  }
  throw new ValidationError('短码生成失败，请稍后重试');
}

export async function getOrCreateFriendCode(userId: string): Promise<string> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { friendCode: true },
  });
  if (!user) {
    throw new NotFoundError('用户');
  }

  if (user.friendCode) {
    return user.friendCode;
  }

  const newCode = await generateUniqueFriendCode();
  // 用 updateMany + friendCode: null 防止并发覆盖（原子性写入）
  const result = await prisma.user.updateMany({
    where: { id: userId, friendCode: null },
    data: { friendCode: newCode },
  });
  if (result.count === 0) {
    // 并发情况下其他请求已写入，重新查询返回已有值
    const existing = await prisma.user.findUnique({
      where: { id: userId },
      select: { friendCode: true },
    });
    if (existing?.friendCode) return existing.friendCode;
    throw new ValidationError('短码生成失败，请稍后重试');
  }
  return newCode;
}

export async function rotateFriendCode(userId: string): Promise<string> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { friendCode: true },
  });
  if (!user) {
    throw new NotFoundError('用户');
  }

  const newCode = await generateUniqueFriendCode(user.friendCode ?? undefined);
  const updated = await prisma.user.update({
    where: { id: userId },
    data: { friendCode: newCode },
    select: { friendCode: true },
  });
  return updated.friendCode as string;
}

export async function lookupByFriendCode(
  userId: string,
  friendCodeInput: string,
): Promise<{ userId: string; nickname: string }> {
  const code = normalizeFriendCode(friendCodeInput);
  if (code.length < FRIEND_CODE_LENGTH) {
    throw new ValidationError('短码长度不足');
  }

  const user = await prisma.user.findUnique({
    where: { friendCode: code },
    select: { id: true, nickname: true },
  });

  if (!user) {
    throw new NotFoundError('好友短码');
  }
  if (user.id === userId) {
    throw new ValidationError('不能添加自己');
  }

  return { userId: user.id, nickname: user.nickname };
}

export async function deleteContact(userId: string, recordId: string): Promise<void> {
  try {
    await prisma.careContact.delete({
      where: { id: recordId, ownerId: userId },
    });
  } catch (e) {
    if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2025') {
      throw new NotFoundError('联系人');
    }
    throw e;
  }
}
