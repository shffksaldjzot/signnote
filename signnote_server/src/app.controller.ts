// ============================================
// 앱 컨트롤러 — 헬스체크 + 대시보드 집계 API
//
// F-3: GET /health (서버 상태 확인)
// D-1: GET /stats/dashboard (대시보드 집계 — 1회 호출로 전체 통계)
// ============================================

import { Controller, Get, UseGuards, Request } from '@nestjs/common';
import { AppService } from './app.service';
import { JwtAuthGuard } from './auth/roles.guard';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  // F-3: 헬스체크 (DB 연결 상태 포함)
  @Get('health')
  async getHealth() {
    return this.appService.getHealth();
  }

  // D-1: 대시보드 집계 API (행사별 계약수/매출/고객수 한번에)
  @Get('stats/dashboard')
  @UseGuards(JwtAuthGuard)
  async getDashboardStats(@Request() req: any) {
    return this.appService.getDashboardStats(req.user.id, req.user.role);
  }
}
