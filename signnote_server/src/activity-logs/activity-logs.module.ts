// ============================================
// 활동 로그 모듈 (ActivityLogs Module)
// ============================================

import { Module, Global } from '@nestjs/common';
import { ActivityLogsController } from './activity-logs.controller';
import { ActivityLogsService } from './activity-logs.service';

@Global()  // 전역 모듈 — 모든 모듈에서 import 없이 사용 가능
@Module({
  controllers: [ActivityLogsController],
  providers: [ActivityLogsService],
  exports: [ActivityLogsService],
})
export class ActivityLogsModule {}
