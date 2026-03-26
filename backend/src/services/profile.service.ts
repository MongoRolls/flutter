import { prisma } from '../config/prisma.js';

export async function getProfile(userId: string) {
  const [user, profile] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, nickname: true, email: true, createdAt: true },
    }),
    prisma.userProfile.findUnique({ where: { userId } }),
  ]);
  return { user, profile };
}

export async function updateProfile(
  userId: string,
  data: {
    nickname?: string;
    dailyGoalMl?: number;
    wakeTimeHour?: number;
    wakeTimeMinute?: number;
    bedTimeHour?: number;
    bedTimeMinute?: number;
    reminderIntervalMin?: number;
    reminderStyle?: string;
    notificationsEnabled?: boolean;
    weightKg?: number;
    activityLevel?: string;
  },
) {
  const { nickname, ...profileFields } = data;

  const [user, profile] = await Promise.all([
    nickname
      ? prisma.user.update({ where: { id: userId }, data: { nickname } })
      : prisma.user.findUnique({ where: { id: userId } }),
    prisma.userProfile.upsert({
      where: { userId },
      update: profileFields,
      create: { userId, ...profileFields },
    }),
  ]);

  return { user, profile };
}
