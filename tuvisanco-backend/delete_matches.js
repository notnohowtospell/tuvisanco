const { PrismaClient } = require('@prisma/client'); const p = new PrismaClient(); p.match.deleteMany({}).then(() => { console.log('Done'); p.$disconnect(); });
