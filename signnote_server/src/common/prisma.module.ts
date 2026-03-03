// ============================================
// Prisma 모듈
// PrismaService를 다른 모듈에서 사용할 수 있게 등록하는 파일
// (배달 서비스 등록처럼, "이 서비스 쓸 수 있어요"라고 알리는 것)
// ============================================

import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global()  // 전역 모듈 - 한 번 등록하면 어디서든 사용 가능
@Module({
  providers: [PrismaService],   // 이 서비스를 제공합니다
  exports: [PrismaService],     // 다른 모듈에서 가져다 쓸 수 있게 내보내기
})
export class PrismaModule {}
