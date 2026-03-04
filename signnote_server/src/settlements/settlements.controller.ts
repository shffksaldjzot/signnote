// ============================================
// 정산 컨트롤러 (Settlements Controller)
//
// API 목록:
//   GET    /api/v1/settlements              → 전체 정산 목록 (주관사)
//   GET    /api/v1/settlements/vendor       → 내 정산 목록 (업체)
//   GET    /api/v1/settlements/vendor/summary → 내 정산 요약 (업체)
//   GET    /api/v1/settlements/:id          → 정산 상세
//   PUT    /api/v1/settlements/:id/transfer → 지급 처리 (주관사)
//   PUT    /api/v1/settlements/:id/complete → 완료 처리 (주관사)
// ============================================

import {
  Controller,
  Get,
  Put,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { SettlementsService } from './settlements.service';
import { JwtAuthGuard, RolesGuard, Roles } from '../auth/roles.guard';

@Controller('settlements')
export class SettlementsController {
  constructor(private readonly settlementsService: SettlementsService) {}

  // 전체 정산 목록 (주관사/관리자용)
  // ?status=PENDING&eventId=xxx 로 필터 가능
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Get()
  async findAll(
    @Query('status') status?: string,
    @Query('eventId') eventId?: string,
  ) {
    return this.settlementsService.findAll(status, eventId);
  }

  // 내 정산 목록 (업체용)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Get('vendor')
  async findByVendor(@Request() req: any) {
    return this.settlementsService.findByVendor(req.user.id);
  }

  // 내 정산 요약 (업체용 - 합계 통계)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Get('vendor/summary')
  async getVendorSummary(@Request() req: any) {
    return this.settlementsService.getVendorSummary(req.user.id);
  }

  // 정산 상세 조회
  @UseGuards(JwtAuthGuard)
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.settlementsService.findOne(id);
  }

  // 지급 처리 (주관사: PENDING → TRANSFERRED)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Put(':id/transfer')
  async transfer(@Param('id') id: string) {
    return this.settlementsService.transfer(id);
  }

  // 완료 처리 (주관사: TRANSFERRED → COMPLETED)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Put(':id/complete')
  async complete(@Param('id') id: string) {
    return this.settlementsService.complete(id);
  }
}
