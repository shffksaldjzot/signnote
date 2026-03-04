// ============================================
// 결제 모듈 (Payments Module)
// 결제 관련 기능을 하나로 묶어주는 역할
// ============================================

import { Module } from '@nestjs/common';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { SettlementsModule } from '../settlements/settlements.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [SettlementsModule, NotificationsModule],  // 결제 완료 → 정산 생성 + 알림
  controllers: [PaymentsController],
  providers: [PaymentsService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
