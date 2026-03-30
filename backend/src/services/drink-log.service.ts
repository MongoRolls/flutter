import { Prisma } from '@prisma/client';

import { prisma } from '../config/prisma.js';
import { NotFoundError } from '../utils/errors.js';

interface DateFilter {
  gte?: Date;
  lt?: Date;
  lte?: Date;
}

// 构建日期过滤条件，支持客户端传入时区偏移（分钟）
function buildDateFilter(
  date?: string,
  startDate?: string,
  endDate?: string,
  tzOffsetMin = 0,
): DateFilter | undefined {
  const offset = tzOffsetMin * 60 * 1000;

  if (date) {
    const dayStart = new Date(new Date(date).getTime() - offset);
    const dayEnd = new Date(dayStart.getTime() + 24 * 60 * 60 * 1000);
    return { gte: dayStart, lt: dayEnd };
  }

  if (startDate || endDate) {
    const filter: DateFilter = {};
    if (startDate) filter.gte = new Date(new Date(startDate).getTime() - offset);
    if (endDate) filter.lte = new Date(new Date(endDate).getTime() - offset + 24 * 60 * 60 * 1000 - 1);
    return filter;
  }

  return undefined;
}

export async function queryLogs(
  userId: string,
  opts: { date?: string; startDate?: string; endDate?: string; limit: number; tzOffsetMin?: number },
) {
  const dateFilter = buildDateFilter(opts.date, opts.startDate, opts.endDate, opts.tzOffsetMin);
  const where: Prisma.DrinkLogWhereInput = {
    userId,
    ...(dateFilter ? { loggedAt: dateFilter } : {}),
  };

  // 用数据库聚合计算 totalMl，避免应用层 reduce 不准确
  const [logs, agg] = await Promise.all([
    prisma.drinkLog.findMany({
      where,
      orderBy: { loggedAt: 'desc' },
      take: opts.limit,
    }),
    prisma.drinkLog.aggregate({
      where,
      _sum: { ml: true },
      _count: true,
    }),
  ]);

  return {
    logs,
    totalMl: agg._sum.ml ?? 0,
    count: agg._count,
  };
}

export async function createLog(
  userId: string,
  data: { ml: number; icon?: string; description?: string; loggedAt?: string },
) {
  return prisma.drinkLog.create({
    data: {
      userId,
      ml: data.ml,
      icon: data.icon ?? '\u{1F4A7}',
      description: data.description ?? '喝水',
      loggedAt: data.loggedAt ? new Date(data.loggedAt) : new Date(),
      syncedAt: new Date(),
    },
  });
}

export async function bulkSync(
  userId: string,
  logs: Array<{ localId: string; ml: number; icon: string; description: string; loggedAt: string }>,
) {
  const now = new Date();

  // 幂等去重：检查哪些 localId 对应的记录已存在（通过 loggedAt + ml + userId 匹配）
  // 简单做法：用事务逐条 upsert 不可行（无 localId 列），采用先查后滤
  const existing = await prisma.drinkLog.findMany({
    where: {
      userId,
      loggedAt: { in: logs.map((l) => new Date(l.loggedAt)) },
    },
    select: { loggedAt: true, ml: true },
  });

  const existingSet = new Set(
    existing.map((e) => `${e.loggedAt.toISOString()}|${e.ml}`),
  );

  const newLogs = logs.filter(
    (l) => !existingSet.has(`${new Date(l.loggedAt).toISOString()}|${l.ml}`),
  );

  if (newLogs.length === 0) {
    return { synced: 0, idMap: [] };
  }

  const created = await prisma.$transaction(
    newLogs.map((l) =>
      prisma.drinkLog.create({
        data: {
          userId,
          ml: l.ml,
          icon: l.icon ?? '\u{1F4A7}',
          description: l.description ?? '喝水',
          loggedAt: new Date(l.loggedAt),
          syncedAt: now,
        },
      }),
    ),
  );

  const idMap = created.map((c, i) => ({
    localId: newLogs[i].localId,
    serverId: c.id,
  }));

  return { synced: idMap.length, idMap };
}

export async function deleteLog(userId: string, logId: string): Promise<void> {
  try {
    await prisma.drinkLog.delete({
      where: { id: logId, userId },
    });
  } catch (e) {
    if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2025') {
      throw new NotFoundError('记录');
    }
    throw e;
  }
}
