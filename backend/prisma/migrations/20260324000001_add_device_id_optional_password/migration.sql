-- AlterTable: add deviceId unique column and make passwordHash optional
ALTER TABLE "User" ADD COLUMN "deviceId" TEXT;

CREATE UNIQUE INDEX "User_deviceId_key" ON "User"("deviceId");

ALTER TABLE "User" ALTER COLUMN "passwordHash" DROP NOT NULL;
