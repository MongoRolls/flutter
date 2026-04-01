import { randomInt } from 'crypto';

import { Prisma } from '@prisma/client';

import {
  FRIEND_CODE_ALPHABET,
  FRIEND_CODE_LENGTH,
  isValidLookupFriendCodeNormalized,
} from '../constants/friend-code.js';
import { MAX_CARE_CONTACTS } from '../constants/care-limits.js';
import {
  PEER_REMIND_TEMPLATE_BODY,
  isValidPeerRemindTemplateId,
} from '../constants/peer-remind.js';
import { prisma } from '../config/prisma.js';
import { NotFoundError, ValidationError } from '../utils/errors.js';
import { buildDateFilter } from './drink-log.service.js';

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

  return prisma.$transaction(async (tx) => {
    const target = await tx.user.findUnique({
      where: { id: contactId },
      select: { id: true },
    });
    if (!target) {
      throw new NotFoundError('目标用户');
    }

    const existingRow = await tx.careContact.findUnique({
      where: { ownerId_contactId: { ownerId: userId, contactId } },
      select: { id: true },
    });
    if (!existingRow) {
      const count = await tx.careContact.count({ where: { ownerId: userId } });
      if (count >= MAX_CARE_CONTACTS) {
        throw new ValidationError(`关怀联系人已达上限（${MAX_CARE_CONTACTS} 人）`);
      }
    }

    return tx.careContact.upsert({
      where: { ownerId_contactId: { ownerId: userId, contactId } },
      update: { nickname },
      create: { ownerId: userId, contactId, nickname },
    });
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

  const exclude = user.friendCode ?? undefined;
  for (let attempt = 0; attempt < 12; attempt++) {
    const newCode = await generateUniqueFriendCode(exclude);
    try {
      const updated = await prisma.user.update({
        where: { id: userId },
        data: { friendCode: newCode },
        select: { friendCode: true },
      });
      return updated.friendCode as string;
    } catch (e: unknown) {
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002'
      ) {
        continue;
      }
      throw e;
    }
  }
  throw new ValidationError('短码更新失败，请稍后重试');
}

export async function lookupByFriendCode(
  userId: string,
  friendCodeInput: string,
): Promise<{ userId: string; nickname: string }> {
  const code = normalizeFriendCode(friendCodeInput);
  if (code.length !== FRIEND_CODE_LENGTH) {
    throw new ValidationError('好友短码须为 6 位');
  }
  if (!isValidLookupFriendCodeNormalized(code)) {
    throw new ValidationError(
      '好友短码须为 6 位大写字母与数字 2–9（不含 0、1）',
    );
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

export type PeerHydrationRow = {
  userId: string;
  todayMl: number | null;
  dailyGoalMl: number | null;
  visible: boolean;
};

/** 当前用户作为 owner 时，各关怀联系人在指定本地日的饮水摘要 */
export async function getPeersHydration(
  ownerId: string,
  date: string,
  tzOffsetMin: number,
): Promise<PeerHydrationRow[]> {
  const contacts = await prisma.careContact.findMany({
    where: { ownerId },
    select: { contactId: true },
    orderBy: { createdAt: 'desc' },
  });
  if (contacts.length === 0) return [];

  const contactIds = [...new Set(contacts.map((c) => c.contactId))];
  const profiles = await prisma.userProfile.findMany({
    where: { userId: { in: contactIds } },
    select: {
      userId: true,
      dailyGoalMl: true,
      shareHydrationWithCareContacts: true,
    },
  });
  const profileByUser = new Map(profiles.map((p) => [p.userId, p]));

  const dateFilter = buildDateFilter(date, undefined, undefined, tzOffsetMin);
  let totalByUser = new Map<string, number>();
  if (dateFilter?.gte != null && dateFilter?.lt != null) {
    const rows = await prisma.$queryRaw<Array<{ userId: string; totalMl: bigint }>>`
      SELECT dl."userId", COALESCE(SUM(dl.ml), 0)::bigint AS "totalMl"
      FROM "DrinkLog" dl
      WHERE dl."userId" IN (${Prisma.join(contactIds)})
        AND dl."loggedAt" >= ${dateFilter.gte}
        AND dl."loggedAt" < ${dateFilter.lt}
      GROUP BY dl."userId"
    `;
    totalByUser = new Map(
      rows.map((r) => [r.userId, Number(r.totalMl)]),
    );
  }

  return contactIds.map((uid) => {
    const prof = profileByUser.get(uid);
    const visible = prof?.shareHydrationWithCareContacts ?? true;
    const rawTotal = totalByUser.get(uid) ?? 0;
    const dailyGoalMl = prof?.dailyGoalMl ?? 2000;
    return {
      userId: uid,
      todayMl: visible ? rawTotal : null,
      dailyGoalMl: visible ? dailyGoalMl : null,
      visible,
    };
  });
}

/** 向关怀联系人发送一次提醒（持久化；远端推送见项目 Phase 说明） */
export async function sendPeerRemind(
  ownerId: string,
  contactId: string,
  templateId: number,
) {
  if (!isValidPeerRemindTemplateId(templateId)) {
    throw new ValidationError('无效的提醒模板');
  }

  const row = await prisma.careContact.findFirst({
    where: { ownerId, contactId },
    select: { id: true },
  });
  if (!row) {
    throw new NotFoundError('关怀联系人');
  }

  return prisma.careReminder.create({
    data: { ownerId, contactId, templateId },
  });
}

/** 获取当前用户最近收到的一条好友提醒（contactId 指向当前用户），附带模板正文 */
export async function getLatestReceivedRemind(userId: string) {
  const row = await prisma.careReminder.findFirst({
    where: { contactId: userId },
    orderBy: { createdAt: 'desc' },
    select: { id: true, ownerId: true, templateId: true, createdAt: true },
  });
  if (!row) return null;
  return {
    ...row,
    templateBody: PEER_REMIND_TEMPLATE_BODY[row.templateId as keyof typeof PEER_REMIND_TEMPLATE_BODY] ?? '',
  };
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
