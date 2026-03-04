// ============================================
// 활동 로그 컨트롤러 (ActivityLogs Controller)
//
// API 목록:
//   GET /api/v1/activity-logs          → 활동 로그 목록 (주관사/관리자)
// ============================================

import {
  Controller,
  Get,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ActivityLogsService } from './activity-logs.service';
import { JwtAuthGuard, RolesGuard, Roles } from '../auth/roles.guard';

@Controller('activity-logs')
export class ActivityLogsController {
  constructor(private readonly activityLogsService: ActivityLogsService) {}

  // 활동 로그 목록 (주관사/관리자만)
  // ?action=LOGIN&userId=xxx&limit=50 로 필터 가능
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Get()
  async findAll(
    @Query('action') action?: string,
    @Query('userId') userId?: string,
    @Query('limit') limit?: string,
  ) {
    return this.activityLogsService.findAll({
      action,
      userId,
      limit: limit ? parseInt(limit, 10) : undefined,
    });
  }
}
