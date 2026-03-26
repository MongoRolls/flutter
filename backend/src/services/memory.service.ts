import { Prisma } from '@prisma/client';

import { prisma } from '../config/prisma.js';
import { NotFoundError } from '../utils/errors.js';

const DEFAULT_PAGE_SIZE = 100;
const MAX_PAGE_SIZE = 500;

export async function listFacts(
  userId: string,
  opts: { limit?: number; offset?: number } = {},
) {
  const take = Math.min(opts.limit ?? DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE);
  const skip = opts.offset ?? 0;

  const [facts, total] = await Promise.all([
    prisma.memoryFact.findMany({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
      take,
      skip,
    }),
    prisma.memoryFact.count({ where: { userId } }),
  ]);

  return { facts, total, limit: take, offset: skip };
}

export async function createFact(
  userId: string,
  data: { category: string; content: string; source?: string },
) {
  return prisma.memoryFact.create({
    data: {
      userId,
      category: data.category,
      content: data.content,
      source: data.source ?? 'chat',
    },
  });
}

export async function deleteFact(userId: string, factId: string): Promise<void> {
  try {
    await prisma.memoryFact.delete({
      where: { id: factId, userId },
    });
  } catch (e) {
    if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2025') {
      throw new NotFoundError('\u8BB0\u5FC6');
    }
    throw e;
  }
}
