const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Bắt đầu dọn dẹp CSDL...');
  await prisma.placedBet.deleteMany();
  await prisma.lobbyMember.deleteMany();
  await prisma.roomCoOwner.deleteMany();
  await prisma.betMarket.deleteMany();
  await prisma.bettingRoom.deleteMany();
  await prisma.freePrediction.deleteMany();
  await prisma.match.deleteMany();
  console.log('CSDL đã được dọn sạch thành công!');
}

main()
  .catch((e) => {
    console.error('Lỗi dọn dẹp:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
