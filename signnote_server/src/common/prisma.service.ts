// ============================================
// Prisma 서비스
// 데이터베이스(창고)와 연결하는 공통 서비스
// 다른 모듈에서 이 서비스를 가져다 쓰면 DB에 접근 가능
// ============================================

import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  // 서버 시작할 때 DB에 연결
  async onModuleInit() {
    await this.$connect();
    console.log('📦 데이터베이스 연결 완료');
  }

  // 서버 종료할 때 DB 연결 해제
  async onModuleDestroy() {
    await this.$disconnect();
    console.log('📦 데이터베이스 연결 해제');
  }
}
