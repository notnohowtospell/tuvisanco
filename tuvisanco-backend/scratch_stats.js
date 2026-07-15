const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const matches = await prisma.match.findMany({
    where: { lineupHome: { not: null } }
  });
  console.log(`Found ${matches.length} matches with lineupHome`);
  if (matches.length > 0) {
    console.log(JSON.stringify(matches[0].lineupHome, null, 2));
  }
}

main().finally(() => prisma.$disconnect());
