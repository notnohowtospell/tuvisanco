const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  const matches = await prisma.match.findMany();
  for (const m of matches) {
    const base = parseInt(m.apiFootballId.replace(/\D/g, '') || '0') % 5;
    const homeYellowCards = base % 3;
    const awayYellowCards = (base + 1) % 3;
    await prisma.match.update({
      where: { id: m.id },
      data: {
        homeYellowCards,
        awayYellowCards,
      }
    });
  }
  console.log('Mock cards updated in DB!');
}

run()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
