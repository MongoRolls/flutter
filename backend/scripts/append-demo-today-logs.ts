/**
 * 不删库：仅向好友码 DEM228 的演示用户追加几条「当前时刻」饮水记录，便于调试今日汇总 / 关怀 hydration。
 *
 * 用法（在 backend/ 下，已配置 DATABASE_URL）：
 *   npx tsx scripts/append-demo-today-logs.ts
 *
 * 若提示未找到用户，先执行：npm run db:seed
 */
import 'dotenv/config';

import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

/** 与 prisma/seed.ts 中演示用户好友码一致（勿从 seed 文件 import，否则会执行整份 seed） */
const DEMO_FRIEND_CODE = 'DEM228';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  console.error('请设置 DATABASE_URL');
  process.exit(1);
}

const adapter = new PrismaPg({ connectionString });
const prisma = new PrismaClient({ adapter });

async function main() {
  const user = await prisma.user.findUnique({
    where: { friendCode: DEMO_FRIEND_CODE },
    select: { id: true, nickname: true },
  });
  if (!user) {
    console.error(
      `未找到好友码 ${DEMO_FRIEND_CODE} 的用户，请先执行: npm run db:seed`,
    );
    process.exit(1);
  }

  const now = new Date();
  const rows = [
    {
      userId: user.id,
      ml: 200,
      icon: '💧',
      description: '调试追加·1',
      loggedAt: new Date(now.getTime() - 45 * 60 * 1000),
    },
    {
      userId: user.id,
      ml: 350,
      icon: '🍵',
      description: '调试追加·2',
      loggedAt: new Date(now.getTime() - 12 * 60 * 1000),
    },
    {
      userId: user.id,
      ml: 280,
      icon: '🧃',
      description: '调试追加·3',
      loggedAt: now,
    },
  ];

  await prisma.drinkLog.createMany({ data: rows });

  const sum = rows.reduce((a, r) => a + r.ml, 0);
  console.log(
    `[append-demo-today] ${user.nickname} (${DEMO_FRIEND_CODE}) 已追加 ${rows.length} 条，合计 +${sum} ml`,
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
