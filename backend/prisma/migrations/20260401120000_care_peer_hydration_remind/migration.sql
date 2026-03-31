-- AlterTable
ALTER TABLE "UserProfile" ADD COLUMN "shareHydrationWithCareContacts" BOOLEAN NOT NULL DEFAULT true;

-- CreateTable
CREATE TABLE "CareReminder" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "contactId" TEXT NOT NULL,
    "templateId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CareReminder_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "CareReminder_ownerId_idx" ON "CareReminder"("ownerId");

-- CreateIndex
CREATE INDEX "CareReminder_contactId_createdAt_idx" ON "CareReminder"("contactId", "createdAt");

-- AddForeignKey
ALTER TABLE "CareReminder" ADD CONSTRAINT "CareReminder_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CareReminder" ADD CONSTRAINT "CareReminder_contactId_fkey" FOREIGN KEY ("contactId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
