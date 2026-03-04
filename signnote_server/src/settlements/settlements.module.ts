// ============================================
// 정산 모듈 (Settlements Module)
// 업체 정산 관리 + 지급대행
// ============================================

import { Module } from '@nestjs/common';
import { SettlementsController } from './settlements.controller';
import { SettlementsService } from './settlements.service';

@Module({
  controllers: [SettlementsController],
  providers: [SettlementsService],
  exports: [SettlementsService],  // 결제 모듈에서 정산 자동 생성 시 사용
})
export class SettlementsModule {}
