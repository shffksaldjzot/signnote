// ============================================
// 관리자 계정 생성 스크립트
//
// 사용법: npx ts-node src/scripts/create-admin.ts
//
// 기본 계정:
//   이메일: admin@signnote.com
//   비밀번호: Signnote2026!
//   역할: ADMIN
// ============================================

import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import * as bcrypt from 'bcrypt';
import 'dotenv/config';

// Prisma v7: adapter 방식으로 DB 연결
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function createAdmin() {
  const email = 'admin@signnote.com';
  const password = 'Signnote2026!';
  const name = '관리자';
  const phone = '010-0000-0000';

  // 이미 존재하는지 확인
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    console.log('⚠️  관리자 계정이 이미 존재합니다:', email);
    console.log('   역할:', existing.role);
    await prisma.$disconnect();
    return;
  }

  // 비밀번호 암호화
  const hashedPassword = await bcrypt.hash(password, 10);

  // 관리자 계정 생성
  const admin = await prisma.user.create({
    data: {
      email,
      password: hashedPassword,
      name,
      phone,
      role: 'ADMIN',
    },
  });

  console.log('✅ 관리자 계정 생성 완료!');
  console.log('   이메일:', email);
  console.log('   비밀번호:', password);
  console.log('   역할:', admin.role);
  console.log('   ID:', admin.id);

  await prisma.$disconnect();
}

createAdmin().catch((e) => {
  console.error('❌ 관리자 계정 생성 실패:', e);
  prisma.$disconnect();
  process.exit(1);
});
