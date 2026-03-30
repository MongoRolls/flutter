-- CreateTable
CREATE TABLE "Challenge" (
    "id"          TEXT         NOT NULL,
    "title"       TEXT         NOT NULL,
    "goalType"    TEXT         NOT NULL DEFAULT 'individual_daily',
    "goalValue"   INTEGER      NOT NULL,
    "periodStart" TIMESTAMP(3) NOT NULL,
    "periodEnd"   TIMESTAMP(3) NOT NULL,
    "status"      TEXT         NOT NULL DEFAULT 'upcoming',
    "inviteCode"  TEXT         NOT NULL,
    "creatorId"   TEXT         NOT NULL,
    "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"   TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Challenge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChallengeMember" (
    "id"                   TEXT         NOT NULL,
    "challengeId"          TEXT         NOT NULL,
    "userId"               TEXT         NOT NULL,
    "role"                 TEXT         NOT NULL DEFAULT 'member',
    "joinedAt"             TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "leftAt"               TIMESTAMP(3),
    "resultAcknowledgedAt" TIMESTAMP(3),
    CONSTRAINT "ChallengeMember_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Challenge_inviteCode_key" ON "Challenge"("inviteCode");
CREATE INDEX "Challenge_status_idx" ON "Challenge"("status");
CREATE INDEX "Challenge_creatorId_idx" ON "Challenge"("creatorId");
CREATE UNIQUE INDEX "ChallengeMember_challengeId_userId_key" ON "ChallengeMember"("challengeId", "userId");
CREATE INDEX "ChallengeMember_userId_idx" ON "ChallengeMember"("userId");
CREATE INDEX "ChallengeMember_challengeId_leftAt_idx" ON "ChallengeMember"("challengeId", "leftAt");

-- AddForeignKey
ALTER TABLE "Challenge"
    ADD CONSTRAINT "Challenge_creatorId_fkey"
    FOREIGN KEY ("creatorId") REFERENCES "User"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ChallengeMember"
    ADD CONSTRAINT "ChallengeMember_challengeId_fkey"
    FOREIGN KEY ("challengeId") REFERENCES "Challenge"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ChallengeMember"
    ADD CONSTRAINT "ChallengeMember_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
