import { prisma } from '../config/prisma.js';

export async function listSummaries(userId: string) {
  return prisma.sessionSummary.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    take: 50,
  });
}

export async function createSummary(userId: string, summary: string) {
  return prisma.sessionSummary.create({
    data: { userId, summary },
  });
}
