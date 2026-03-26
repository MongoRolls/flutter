import { Prisma } from '@prisma/client';

import { prisma } from '../config/prisma.js';
import { NotFoundError } from '../utils/errors.js';

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
  return prisma.careContact.upsert({
    where: { ownerId_contactId: { ownerId: userId, contactId } },
    update: { nickname },
    create: { ownerId: userId, contactId, nickname },
  });
}

export async function deleteContact(userId: string, recordId: string): Promise<void> {
  try {
    await prisma.careContact.delete({
      where: { id: recordId, ownerId: userId },
    });
  } catch (e) {
    if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2025') {
      throw new NotFoundError('\u8054\u7CFB\u4EBA');
    }
    throw e;
  }
}
