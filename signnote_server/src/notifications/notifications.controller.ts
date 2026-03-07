// ============================================
// 알림 컨트롤러 (Notifications Controller)
//
// API 목록:
//   GET    /api/v1/notifications           → 내 알림 목록
//   GET    /api/v1/notifications/unread    → 안 읽은 알림 개수
//   PUT    /api/v1/notifications/:id/read  → 알림 읽음 처리
//   PUT    /api/v1/notifications/read-all  → 전체 읽음 처리
//   POST   /api/v1/notifications/fcm-token → FCM 토큰 등록
// ============================================

import {
  Controller,
  Get,
  Put,
  Post,
  Param,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/roles.guard';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  // 내 알림 목록 (최근 50개)
  @UseGuards(JwtAuthGuard)
  @Get()
  async findMine(@Request() req: any) {
    return this.notificationsService.findByUser(req.user.id);
  }

  // 특정 행사의 알림 목록
  @UseGuards(JwtAuthGuard)
  @Get('event/:eventId')
  async findByEvent(@Request() req: any, @Param('eventId') eventId: string) {
    return this.notificationsService.findByEvent(req.user.id, eventId);
  }

  // 안 읽은 알림 개수
  @UseGuards(JwtAuthGuard)
  @Get('unread')
  async getUnreadCount(@Request() req: any) {
    const count = await this.notificationsService.getUnreadCount(req.user.id);
    return { count };
  }

  // 행사별 안 읽은 알림 개수 (주관사 홈에서 빨간 뱃지용)
  @UseGuards(JwtAuthGuard)
  @Get('unread-by-events')
  async getUnreadCountByEvents(@Request() req: any) {
    return this.notificationsService.getUnreadCountByEvents(req.user.id);
  }

  // 알림 읽음 처리
  @UseGuards(JwtAuthGuard)
  @Put(':id/read')
  async markAsRead(@Request() req: any, @Param('id') id: string) {
    await this.notificationsService.markAsRead(id, req.user.id);
    return { success: true };
  }

  // 전체 읽음 처리
  @UseGuards(JwtAuthGuard)
  @Put('read-all')
  async markAllAsRead(@Request() req: any) {
    await this.notificationsService.markAllAsRead(req.user.id);
    return { success: true };
  }

  // FCM 토큰 등록 (앱에서 푸시 알림 받기 위해 필요)
  @UseGuards(JwtAuthGuard)
  @Post('fcm-token')
  async registerFcmToken(
    @Request() req: any,
    @Body('token') token: string,
  ) {
    await this.notificationsService.registerFcmToken(req.user.id, token);
    return { success: true };
  }
}
