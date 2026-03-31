-- AlterTable
ALTER TABLE "MemoryFact" DROP CONSTRAINT "MemoryFact_userId_fkey";

-- AlterTable
ALTER TABLE "SessionSummary" DROP CONSTRAINT "SessionSummary_userId_fkey";

-- AlterTable
ALTER TABLE "TodayPlan" DROP CONSTRAINT "TodayPlan_userId_fkey";

-- DropTable
DROP TABLE "MemoryFact";

-- DropTable
DROP TABLE "SessionSummary";

-- DropTable
DROP TABLE "TodayPlan";
