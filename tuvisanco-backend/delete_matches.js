const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

async function main() {
  console.log('Đang dọn dẹp cơ sở dữ liệu để reset sạch sẽ...');
  
  // 1. Xóa các bảng liên quan đến đặt cược và thành viên phòng
  await p.placedBet.deleteMany({});
  await p.betMarket.deleteMany({});
  await p.lobbyMember.deleteMany({});
  await p.roomCoOwner.deleteMany({});
  
  // 2. Xóa các phòng cược
  await p.bettingRoom.deleteMany({});
  
  // 3. Xóa các dự đoán miễn phí
  await p.freePrediction.deleteMany({});
  
  // 4. Xóa tất cả trận đấu cũ
  await p.match.deleteMany({});
  
  console.log('Đã dọn dẹp cơ sở dữ liệu thành công!');
}

main()
  .catch(console.error)
  .finally(() => p.$disconnect());
