import type { Prisma } from '@prisma/client';

import { prisma } from '../config/prisma.js';

export async function getPlan(userId: string, date: string) {
  return prisma.todayPlan.findUnique({
    where: { userId_date: { userId, date: new Date(date) } },
  });
}

export async function upsertPlan(
  userId: string,
  date: string,
  planJson: Prisma.InputJsonValue,
) {
  return prisma.todayPlan.upsert({
    where: { userId_date: { userId, date: new Date(date) } },
    update: { planJson },
    create: { userId, date: new Date(date), planJson },
  });
}
