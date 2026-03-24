-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "phone" TEXT,
    "email" TEXT,
    "passwordHash" TEXT NOT NULL,
    "nickname" TEXT NOT NULL DEFAULT '水友',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserProfile" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "dailyGoalMl" INTEGER NOT NULL DEFAULT 2000,
    "wakeTimeHour" INTEGER NOT NULL DEFAULT 7,
    "wakeTimeMinute" INTEGER NOT NULL DEFAULT 0,
    "bedTimeHour" INTEGER NOT NULL DEFAULT 23,
    "bedTimeMinute" INTEGER NOT NULL DEFAULT 0,
    "reminderIntervalMin" INTEGER NOT NULL DEFAULT 60,
    "reminderStyle" TEXT NOT NULL DEFAULT 'gentle',
    "notificationsEnabled" BOOLEAN NOT NULL DEFAULT true,
    "weightKg" DOUBLE PRECISION,
    "activityLevel" TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DrinkLog" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "ml" INTEGER NOT NULL,
    "icon" TEXT NOT NULL DEFAULT '💧',
    "description" TEXT NOT NULL DEFAULT '喝水',
    "loggedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "syncedAt" TIMESTAMP(3),

    CONSTRAINT "DrinkLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MemoryFact" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "source" TEXT NOT NULL DEFAULT 'chat',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MemoryFact_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SessionSummary" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "summary" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SessionSummary_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TodayPlan" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "planJson" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TodayPlan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CareContact" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "contactId" TEXT NOT NULL,
    "nickname" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CareContact_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_phone_key" ON "User"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "UserProfile_userId_key" ON "UserProfile"("userId");

-- CreateIndex
CREATE INDEX "DrinkLog_userId_loggedAt_idx" ON "DrinkLog"("userId", "loggedAt");

-- CreateIndex
CREATE INDEX "MemoryFact_userId_idx" ON "MemoryFact"("userId");

-- CreateIndex
CREATE INDEX "SessionSummary_userId_idx" ON "SessionSummary"("userId");

-- CreateIndex
CREATE INDEX "TodayPlan_userId_idx" ON "TodayPlan"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "TodayPlan_userId_date_key" ON "TodayPlan"("userId", "date");

-- CreateIndex
CREATE INDEX "CareContact_ownerId_idx" ON "CareContact"("ownerId");

-- CreateIndex
CREATE UNIQUE INDEX "CareContact_ownerId_contactId_key" ON "CareContact"("ownerId", "contactId");

-- AddForeignKey
ALTER TABLE "UserProfile" ADD CONSTRAINT "UserProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DrinkLog" ADD CONSTRAINT "DrinkLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MemoryFact" ADD CONSTRAINT "MemoryFact_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SessionSummary" ADD CONSTRAINT "SessionSummary_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TodayPlan" ADD CONSTRAINT "TodayPlan_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CareContact" ADD CONSTRAINT "CareContact_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CareContact" ADD CONSTRAINT "CareContact_contactId_fkey" FOREIGN KEY ("contactId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
