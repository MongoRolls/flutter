import { randomInt } from 'crypto';

import { Prisma } from '@prisma/client';

import { prisma } from '../config/prisma.js';
import { ConflictError, ForbiddenError, NotFoundError, ValidationError } from '../utils/errors.js';

const INVITE_CODE_LENGTH = 6;
const INVITE_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const CHALLENGE_MAX_MEMBERS = 20;

function createCandidateCode(): string {
  let code = '';
  for (let i = 0; i < INVITE_CODE_LENGTH; i++) {
    code += INVITE_CODE_ALPHABET[randomInt(0, INVITE_CODE_ALPHABET.length)] as string;
  }
  return code;
}

function isValidCalendarYmd(year: number, month: number, day: number): boolean {
  if (month < 1 || month > 12 || day < 1 || day > 31) return false;
  const dt = new Date(Date.UTC(year, month - 1, day));
  return dt.getUTCFullYear() === year && dt.getUTCMonth() === month - 1 && dt.getUTCDate() === day;
}

/** 客户端 localDate (YYYY-MM-DD) + 时区偏移分钟 → 当日 UTC 区间 [start, end) */
export function localDateToUtcRange(localDate: string, tzOffsetMin: number): { start: Date; end: Date } {
  const parts = localDate.split('-').map(Number);
  if (parts.length !== 3 || parts.some((n) => Number.isNaN(n))) {
    throw new ValidationError('localDate 格式应为 YYYY-MM-DD');
  }
  const [y, m, d] = parts;
  if (!isValidCalendarYmd(y, m, d)) {
    throw new ValidationError('localDate 日期不合法');
  }
  const utcStart = new Date(Date.UTC(y, m - 1, d, 0, 0, 0, 0) - tzOffsetMin * 60 * 1000);
  const utcEnd = new Date(utcStart.getTime() + 24 * 60 * 60 * 1000);
  return { start: utcStart, end: utcEnd };
}

function computeLiveStatus(
  periodStart: Date,
  periodEnd: Date,
  now: Date,
): 'upcoming' | 'active' | 'settled' {
  if (now < periodStart) return 'upcoming';
  if (now <= periodEnd) return 'active';
  return 'settled';
}

async function persistChallengeStatusIfNeeded(challenge: {
  id: string;
  periodStart: Date;
  periodEnd: Date;
  status: string;
}): Promise<boolean> {
  const now = new Date();
  const live = computeLiveStatus(challenge.periodStart, challenge.periodEnd, now);
  if (challenge.status !== live) {
    await prisma.challenge.update({
      where: { id: challenge.id },
      data: { status: live },
    });
    return true;
  }
  return false;
}

async function persistChallengeStatusIfNeededTx(
  tx: Prisma.TransactionClient,
  challenge: {
    id: string;
    periodStart: Date;
    periodEnd: Date;
    status: string;
  },
): Promise<void> {
  const now = new Date();
  const live = computeLiveStatus(challenge.periodStart, challenge.periodEnd, now);
  if (challenge.status !== live) {
    await tx.challenge.update({
      where: { id: challenge.id },
      data: { status: live },
    });
  }
}

export interface CreateChallengeDto {
  title: string;
  goalType?: string;
  goalValue: number;
  periodStart: string;
  periodEnd: string;
}

export async function createChallenge(userId: string, data: CreateChallengeDto) {
  const goalType = data.goalType ?? 'individual_daily';
  if (data.goalValue < 1 || data.goalValue > 20000) {
    throw new ValidationError('goalValue 不合法');
  }
  const periodStart = new Date(data.periodStart);
  const periodEnd = new Date(data.periodEnd);
  if (Number.isNaN(periodStart.getTime()) || Number.isNaN(periodEnd.getTime())) {
    throw new ValidationError('日期格式无效');
  }
  if (periodEnd <= periodStart) {
    throw new ValidationError('结束时间必须晚于开始时间');
  }

  const now = new Date();
  const initialStatus = computeLiveStatus(periodStart, periodEnd, now);

  return prisma.$transaction(async (tx) => {
    for (let attempt = 0; attempt < 12; attempt++) {
      const inviteCode = createCandidateCode();
      try {
        const challenge = await tx.challenge.create({
          data: {
            title: data.title.trim().slice(0, 80),
            goalType,
            goalValue: data.goalValue,
            periodStart,
            periodEnd,
            status: initialStatus,
            inviteCode,
            creatorId: userId,
          },
        });
        await tx.challengeMember.create({
          data: {
            challengeId: challenge.id,
            userId,
            role: 'leader',
          },
        });
        return challenge;
      } catch (e) {
        if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
          continue;
        }
        throw e;
      }
    }
    throw new ValidationError('邀请码生成失败，请稍后重试');
  });
}

export async function joinChallenge(userId: string, inviteCodeRaw: string) {
  const code = inviteCodeRaw.trim().replaceAll(' ', '').toUpperCase();
  if (code.length !== INVITE_CODE_LENGTH) {
    throw new ValidationError('邀请码长度应为 6 位');
  }

  return prisma.$transaction(async (tx) => {
    const challenge = await tx.challenge.findUnique({
      where: { inviteCode: code },
    });
    if (!challenge) {
      throw new NotFoundError('挑战');
    }

    await persistChallengeStatusIfNeededTx(tx, challenge);

    let refreshed = await tx.challenge.findUnique({ where: { id: challenge.id } });
    if (!refreshed) throw new NotFoundError('挑战');

    if (refreshed.status === 'settled') {
      throw new ValidationError('挑战已结束，无法加入');
    }
    if (refreshed.creatorId === userId) {
      throw new ValidationError('你是发起人，无需重复加入');
    }

    const existing = await tx.challengeMember.findUnique({
      where: { challengeId_userId: { challengeId: refreshed.id, userId } },
    });
    if (existing && existing.leftAt == null) {
      throw new ConflictError('已在该挑战中');
    }

    const activeCount = await tx.challengeMember.count({
      where: { challengeId: refreshed.id, leftAt: null },
    });
    if (activeCount >= CHALLENGE_MAX_MEMBERS) {
      throw new ValidationError('挑战人数已满');
    }

    await tx.challengeMember.upsert({
      where: { challengeId_userId: { challengeId: refreshed.id, userId } },
      create: {
        challengeId: refreshed.id,
        userId,
        role: 'member',
      },
      update: {
        leftAt: null,
        role: 'member',
        joinedAt: new Date(),
      },
    });

    return refreshed;
  });
}

/** 拉取我的挑战（全量；客户端可传 localDate / tzOffset 计算 selfContributed） */
export async function getMyChallengesFull(
  userId: string,
  localDate?: string,
  tzOffsetMin?: number,
) {
  const memberships = await prisma.challengeMember.findMany({
    where: { userId, leftAt: null },
    include: { challenge: true },
    orderBy: { joinedAt: 'desc' },
  });

  if (memberships.length === 0) {
    return { items: [], syncedAt: new Date().toISOString() };
  }

  const tz = tzOffsetMin ?? 0;
  let ld = localDate;
  if (!ld) {
    const now = new Date();
    const utc = new Date(now.getTime() + tz * 60 * 1000);
    const y = utc.getUTCFullYear();
    const m = String(utc.getUTCMonth() + 1).padStart(2, '0');
    const d = String(utc.getUTCDate()).padStart(2, '0');
    ld = `${y}-${m}-${d}`;
  }
  const { start: dayStart, end: dayEnd } = localDateToUtcRange(ld, tz);

  const myToday = await prisma.drinkLog.aggregate({
    where: {
      userId,
      loggedAt: { gte: dayStart, lt: dayEnd },
    },
    _sum: { ml: true },
  });
  const todayMl = myToday._sum.ml ?? 0;

  const challengeRows = memberships.map((m) => m.challenge);
  const challengeIds = challengeRows.map((c) => c.id);
  const now = new Date();

  const statusUpdates: { id: string; status: string }[] = [];
  for (const c of challengeRows) {
    const live = computeLiveStatus(c.periodStart, c.periodEnd, now);
    if (c.status !== live) {
      statusUpdates.push({ id: c.id, status: live });
    }
  }
  if (statusUpdates.length > 0) {
    await prisma.$transaction(
      statusUpdates.map((u) =>
        prisma.challenge.update({ where: { id: u.id }, data: { status: u.status } }),
      ),
    );
  }

  const statusById = new Map(statusUpdates.map((u) => [u.id, u.status]));

  const teamTotals =
    challengeIds.length > 0
      ? await prisma.$queryRaw<Array<{ challengeId: string; total: bigint }>>`
          SELECT cm."challengeId", COALESCE(SUM(d.ml), 0)::bigint AS total
          FROM "ChallengeMember" cm
          INNER JOIN "Challenge" c ON c.id = cm."challengeId"
          INNER JOIN "DrinkLog" d ON d."userId" = cm."userId"
            AND d."loggedAt" >= c."periodStart"
            AND d."loggedAt" <= c."periodEnd"
          WHERE cm."challengeId" IN (${Prisma.join(challengeIds)})
            AND cm."leftAt" IS NULL
          GROUP BY cm."challengeId"
        `
      : [];

  const teamMlMap = new Map<string, number>();
  for (const id of challengeIds) {
    teamMlMap.set(id, 0);
  }
  for (const row of teamTotals) {
    teamMlMap.set(row.challengeId, Number(row.total));
  }

  const memberCounts = await prisma.challengeMember.groupBy({
    by: ['challengeId'],
    where: { challengeId: { in: challengeIds }, leftAt: null },
    _count: { _all: true },
  });
  const memberCountMap = new Map(memberCounts.map((x) => [x.challengeId, x._count._all]));

  const items: Array<Record<string, unknown>> = [];

  for (const m of memberships) {
    const c = m.challenge;
    const live = computeLiveStatus(c.periodStart, c.periodEnd, now);
    const status = statusById.get(c.id) ?? live;

    const teamMl = teamMlMap.get(c.id) ?? 0;
    const selfContributed =
      c.goalType === 'team_total' ? teamMl >= c.goalValue : todayMl >= c.goalValue;

    const memberCount = memberCountMap.get(c.id) ?? 0;

    const lastEventAt = c.updatedAt > m.joinedAt ? c.updatedAt : m.joinedAt;

    items.push({
      challengeId: c.id,
      title: c.title,
      status,
      role: m.role,
      goalType: c.goalType,
      goalValue: c.goalValue,
      periodStart: c.periodStart.toISOString(),
      periodEnd: c.periodEnd.toISOString(),
      teamProgress: teamMl,
      memberCount,
      myTodayMl: todayMl,
      selfContributed,
      resultAcknowledgedAt: m.resultAcknowledgedAt?.toISOString() ?? null,
      lastEventAt: lastEventAt.toISOString(),
      inviteCode: m.role === 'leader' ? c.inviteCode : null,
    });
  }

  return { items, syncedAt: new Date().toISOString() };
}

export async function getChallengeDetail(userId: string, challengeId: string) {
  const m = await prisma.challengeMember.findFirst({
    where: { challengeId, userId, leftAt: null },
    include: {
      challenge: {
        include: {
          members: {
            where: { leftAt: null },
            include: { user: { select: { id: true, nickname: true } } },
          },
        },
      },
    },
  });
  if (!m) {
    throw new ForbiddenError('无权查看该挑战');
  }
  let c = m.challenge;
  const statusChanged = await persistChallengeStatusIfNeeded(c);
  if (statusChanged) {
    const c2 = await prisma.challenge.findUnique({
      where: { id: challengeId },
      include: {
        members: {
          where: { leftAt: null },
          include: { user: { select: { id: true, nickname: true } } },
        },
      },
    });
    if (!c2) throw new NotFoundError('挑战');
    c = c2;
  }

  return {
    challengeId: c.id,
    title: c.title,
    status: c.status,
    goalType: c.goalType,
    goalValue: c.goalValue,
    periodStart: c.periodStart.toISOString(),
    periodEnd: c.periodEnd.toISOString(),
    inviteCode: c.inviteCode,
    members: c.members.map((mem) => ({
      userId: mem.userId,
      nickname: mem.user.nickname,
      role: mem.role,
      joinedAt: mem.joinedAt.toISOString(),
    })),
  };
}

export async function leaveChallenge(userId: string, challengeId: string) {
  const m = await prisma.challengeMember.findUnique({
    where: { challengeId_userId: { challengeId, userId } },
    include: { challenge: true },
  });
  if (!m || m.leftAt) {
    throw new NotFoundError('参与记录');
  }

  const now = new Date();

  await prisma.$transaction(async (tx) => {
    await tx.challengeMember.update({
      where: { id: m.id },
      data: { leftAt: now },
    });

    if (m.role === 'leader') {
      const others = await tx.challengeMember.findMany({
        where: { challengeId, userId: { not: userId }, leftAt: null },
        orderBy: { joinedAt: 'asc' },
        take: 1,
      });
      if (others.length > 0) {
        await tx.challengeMember.update({
          where: { id: others[0].id },
          data: { role: 'leader' },
        });
      } else {
        await tx.challenge.update({
          where: { id: challengeId },
          data: { status: 'settled' },
        });
      }
    }
  });
}

export async function ackResult(userId: string, challengeId: string) {
  const m = await prisma.challengeMember.findUnique({
    where: { challengeId_userId: { challengeId, userId } },
    include: { challenge: true },
  });
  if (!m || m.leftAt) {
    throw new NotFoundError('参与记录');
  }

  await persistChallengeStatusIfNeeded(m.challenge);
  const c = await prisma.challenge.findUnique({ where: { id: challengeId } });
  if (!c) {
    throw new NotFoundError('挑战');
  }
  if (c.status !== 'settled') {
    throw new ValidationError('挑战尚未结束，暂无法确认成绩');
  }

  await prisma.challengeMember.update({
    where: { id: m.id },
    data: { resultAcknowledgedAt: new Date() },
  });

  return { ok: true };
}
