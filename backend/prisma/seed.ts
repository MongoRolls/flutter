/**
 * 开发/联调用：插入固定「测试好友」+「演示账号」，含多日饮水记录，便于关怀/同步/图表联调。
 *
 * 运行：npm run db:seed（需已配置 DATABASE_URL 并完成 migrate）
 *
 * 测试账号通过稳定 deviceId upsert，重复执行会刷新档案、好友码与饮水记录（仅作用于种子用户）。
 */
import 'dotenv/config';

import { isValidFriendCodeNormalized } from '../src/constants/friend-code.js';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is required for prisma db seed');
}

const adapter = new PrismaPg({ connectionString });
const prisma = new PrismaClient({ adapter });

/** 与客户端/规格一致：仅用于种子用户，勿与真实设备冲突 */
const SEED_TEST_PEER_DEVICE_ID = '__keleme_seed_test_peer__';
/** 正常数据演示账号（可当作「路人用户」联调喝水同步） */
const SEED_DEMO_USER_DEVICE_ID = '__keleme_seed_demo_user__';

/**
 * 6 位好友码（字母 A–Z + 数字 2–9，不含 0/1；见 src/constants/friend-code.ts）。
 */
export const TEST_PEER_FRIEND_CODE = 'KELE22';
/** 演示账号好友码（添加队友 / 好友码查询） */
export const TEST_DEMO_FRIEND_CODE = 'DEM228';

function dayAtOffset(
  now: Date,
  dayOffset: number,
  hour: number,
  minute: number,
): Date {
  const d = new Date(now);
  d.setDate(d.getDate() - dayOffset);
  d.setHours(hour, minute, 0, 0);
  return d;
}

async function main() {
  if (!isValidFriendCodeNormalized(TEST_PEER_FRIEND_CODE)) {
    throw new Error(
      `TEST_PEER_FRIEND_CODE 非法：须为 6 位且属于字母表（见 src/constants/friend-code.ts）`,
    );
  }
  if (!isValidFriendCodeNormalized(TEST_DEMO_FRIEND_CODE)) {
    throw new Error(`TEST_DEMO_FRIEND_CODE 非法`);
  }

  const peer = await prisma.user.upsert({
    where: { deviceId: SEED_TEST_PEER_DEVICE_ID },
    create: {
      deviceId: SEED_TEST_PEER_DEVICE_ID,
      nickname: '测试好友',
      friendCode: TEST_PEER_FRIEND_CODE,
      profile: {
        create: {
          dailyGoalMl: 2000,
          wakeTimeHour: 7,
          wakeTimeMinute: 0,
          bedTimeHour: 23,
          bedTimeMinute: 0,
          reminderIntervalMin: 60,
          reminderStyle: 'gentle',
          weightKg: 65,
          activityLevel: '久坐',
        },
      },
    },
    update: {
      nickname: '测试好友',
      friendCode: TEST_PEER_FRIEND_CODE,
    },
  });

  const demo = await prisma.user.upsert({
    where: { deviceId: SEED_DEMO_USER_DEVICE_ID },
    create: {
      deviceId: SEED_DEMO_USER_DEVICE_ID,
      nickname: '演示用户',
      friendCode: TEST_DEMO_FRIEND_CODE,
      profile: {
        create: {
          dailyGoalMl: 2000,
          wakeTimeHour: 7,
          wakeTimeMinute: 30,
          bedTimeHour: 23,
          bedTimeMinute: 0,
          reminderIntervalMin: 60,
          reminderStyle: 'gentle',
          notificationsEnabled: true,
          weightKg: 58,
          activityLevel: '中等',
        },
      },
    },
    update: {
      nickname: '演示用户',
      friendCode: TEST_DEMO_FRIEND_CODE,
    },
  });

  await prisma.userProfile.update({
    where: { userId: peer.id },
    data: {
      dailyGoalMl: 2000,
      wakeTimeHour: 7,
      wakeTimeMinute: 0,
      bedTimeHour: 23,
      bedTimeMinute: 0,
      reminderIntervalMin: 60,
      reminderStyle: 'gentle',
      weightKg: 65,
      activityLevel: '久坐',
    },
  });

  await prisma.userProfile.update({
    where: { userId: demo.id },
    data: {
      dailyGoalMl: 2000,
      wakeTimeHour: 7,
      wakeTimeMinute: 30,
      bedTimeHour: 23,
      bedTimeMinute: 0,
      reminderIntervalMin: 60,
      reminderStyle: 'gentle',
      notificationsEnabled: true,
      weightKg: 58,
      activityLevel: '中等',
    },
  });

  await prisma.drinkLog.deleteMany({
    where: { userId: { in: [peer.id, demo.id] } },
  });

  const now = new Date();

  /** 测试好友：近 3 天少量记录 */
  const peerLogs: { ml: number; icon: string; description: string; loggedAt: Date }[] =
    [];
  for (let day = 0; day <= 2; day++) {
    peerLogs.push(
      {
        ml: 280,
        icon: '💧',
        description: '晨起一杯',
        loggedAt: dayAtOffset(now, day, 7, 20),
      },
      {
        ml: 350,
        icon: '🍵',
        description: '上午补水',
        loggedAt: dayAtOffset(now, day, 10, 45),
      },
      {
        ml: 400,
        icon: '💧',
        description: '午后',
        loggedAt: dayAtOffset(now, day, 14, 30),
      },
    );
  }

  /** 演示用户：近 8 天（含今天）更丰富记录，总量有高有低 */
  const demoDailyTotals = [1650, 2100, 1880, 920, 2050, 1980, 2200, 1760];
  const demoLogs: { ml: number; icon: string; description: string; loggedAt: Date }[] =
    [];

  const slotTemplates: {
    ratio: number;
    hour: number;
    minute: number;
    icon: string;
    description: string;
  }[][] = [
    [
      { ratio: 0.35, hour: 7, minute: 20, icon: '💧', description: '晨起' },
      { ratio: 0.3, hour: 11, minute: 5, icon: '🍵', description: '上午' },
      { ratio: 0.35, hour: 16, minute: 40, icon: '🧃', description: '下午' },
    ],
    [
      { ratio: 0.32, hour: 7, minute: 15, icon: '💧', description: '起床喝水' },
      { ratio: 0.28, hour: 10, minute: 30, icon: '🍵', description: '工间' },
      { ratio: 0.22, hour: 13, minute: 45, icon: '💧', description: '午饭后' },
      { ratio: 0.18, hour: 19, minute: 0, icon: '💧', description: '晚饭后' },
    ],
  ];

  for (let dayIdx = 0; dayIdx < demoDailyTotals.length; dayIdx++) {
    const total = demoDailyTotals[dayIdx]!;
    const slots = slotTemplates[dayIdx % 2]!;
    let allocated = 0;
    for (let i = 0; i < slots.length; i++) {
      const s = slots[i]!;
      const ml =
        i === slots.length - 1
          ? total - allocated
          : Math.round(total * s.ratio);
      allocated += ml;
      demoLogs.push({
        ml,
        icon: s.icon,
        description: s.description,
        loggedAt: dayAtOffset(now, dayIdx, s.hour, s.minute),
      });
    }
  }

  await prisma.drinkLog.createMany({
    data: [
      ...peerLogs.map((e) => ({ userId: peer.id, ...e })),
      ...demoLogs.map((e) => ({ userId: demo.id, ...e })),
    ],
  });

  // 再追加「当前时刻」附近几条，避免服务器时区与客户端 tzOffset 导致「今日」汇总为 0（关怀 peers/hydration 联调）
  const t = new Date();
  await prisma.drinkLog.createMany({
    data: [
      {
        userId: demo.id,
        ml: 180,
        icon: '💧',
        description: 'seed·调试·今日',
        loggedAt: new Date(t.getTime() - 15 * 60 * 1000),
      },
      {
        userId: demo.id,
        ml: 220,
        icon: '🍵',
        description: 'seed·调试·今日',
        loggedAt: t,
      },
    ],
  });

  console.log(
    `[seed] 测试好友：好友码 ${TEST_PEER_FRIEND_CODE}（userId=${peer.id}），饮水 ${peerLogs.length} 条`,
  );
  console.log(
    `[seed] 演示用户：好友码 ${TEST_DEMO_FRIEND_CODE}（userId=${demo.id}），饮水 ${demoLogs.length} 条（近 8 天）+ 2 条「当前时刻」调试`,
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
