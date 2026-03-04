// ============================================
// 알림 모듈 (Notifications Module)
// FCM 푸시 + 카카오 알림톡 + 앱 내 알림
// ============================================

import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';

@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService],
  exports: [NotificationsService],  // 다른 모듈(Contracts 등)에서 알림 전송 가능
})
export class NotificationsModule {}
