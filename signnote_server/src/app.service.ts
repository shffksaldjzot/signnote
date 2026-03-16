// ============================================
// 앱 서비스 — 헬스체크 + 대시보드 집계
//
// F-3: 서버/DB 상태 확인
// D-1: 대시보드 집계 (N+1 쿼리 해결 — 1회 호출로 전체 통계)
// ============================================

import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from './common/prisma.service';

@Injectable()
export class AppService {
  private readonly logger = new Logger('AppService');

  constructor(private readonly prisma: PrismaService) {}

  getHello(): string {
    return 'Signnote API v1';
  }

  // F-3: 헬스체크 (서버 + DB 상태)
  async getHealth() {
    let dbStatus = 'ok';
    try {
      // 간단한 쿼리로 DB 연결 확인
      await this.prisma.user.count();
    } catch (e) {
      dbStatus = 'error';
      this.logger.error('DB 연결 실패', e);
    }

    return {
      status: dbStatus === 'ok' ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      database: dbStatus,
      uptime: process.uptime(),
    };
  }

  // D-1: 대시보드 집계 API (프론트에서 행사별 for문 호출 제거)
  async getDashboardStats(userId: string, role: string) {
    // 행사 목록 (역할별)
    let eventWhere: any = { deletedAt: null };
    if (role === 'ORGANIZER') {
      eventWhere = { organizerId: userId, deletedAt: null };
    }
    // ADMIN은 전체

    const events = await this.prisma.event.findMany({
      where: role === 'ADMIN' ? {} : eventWhere,
      select: {
        id: true,
        title: true,
        startDate: true,
        endDate: true,
        deletedAt: true,
        organizer: { select: { id: true, name: true } },
      },
      orderBy: { startDate: 'desc' },
    });

    const eventIds = events.map(e => e.id);

    // 전체 계약 집계 (행사별 그룹핑) — 1회 쿼리
    const contracts = await this.prisma.contract.groupBy({
      by: ['eventId', 'status'],
      where: { eventId: { in: eventIds } },
      _count: { id: true },
      _sum: { depositAmount: true, originalPrice: true },
    });

    // 행사별 참여자 수 (고객만) — 1회 쿼리
    const participantCounts = await this.prisma.eventParticipant.groupBy({
      by: ['eventId'],
      where: {
        eventId: { in: eventIds },
        user: { role: 'CUSTOMER' },
      },
      _count: { id: true },
    });

    // 미승인 업체 수
    const unapprovedVendors = await this.prisma.user.count({
      where: { role: 'VENDOR', isApproved: false },
    });

    // 전체 업체 수
    const totalVendors = await this.prisma.user.count({
      where: { role: 'VENDOR' },
    });

    // 전체 고객 수
    const totalCustomers = await this.prisma.user.count({
      where: { role: 'CUSTOMER' },
    });

    // 행사별 집계 맵 구성
    const eventStats: Record<string, any> = {};
    for (const e of events) {
      eventStats[e.id] = {
        eventId: e.id,
        title: e.title,
        startDate: e.startDate,
        endDate: e.endDate,
        deletedAt: e.deletedAt,
        organizerName: e.organizer?.name ?? '-',
        contracts: { total: 0, confirmed: 0, pending: 0, cancelRequested: 0, cancelled: 0 },
        revenue: 0,       // 확정 계약 계약금 합계
        totalAmount: 0,   // 확정 계약 총액 합계
        customerCount: 0,
      };
    }

    // 계약 집계 반영
    for (const row of contracts) {
      const stat = eventStats[row.eventId];
      if (!stat) continue;
      const count = row._count.id;
      const depositSum = row._sum.depositAmount ?? 0;
      const priceSum = row._sum.originalPrice ?? 0;
      stat.contracts.total += count;

      switch (row.status) {
        case 'CONFIRMED':
          stat.contracts.confirmed += count;
          stat.revenue += depositSum;
          stat.totalAmount += priceSum;
          break;
        case 'PENDING':
          stat.contracts.pending += count;
          break;
        case 'CANCEL_REQUESTED':
          stat.contracts.cancelRequested += count;
          break;
        case 'CANCELLED':
          stat.contracts.cancelled += count;
          break;
      }
    }

    // 참여자 수 반영
    for (const row of participantCounts) {
      const stat = eventStats[row.eventId];
      if (stat) stat.customerCount = row._count.id;
    }

    // 전체 합계 계산
    const allStats = Object.values(eventStats);
    const totalContracts = allStats.reduce((s: number, e: any) => s + e.contracts.total, 0);
    const totalConfirmed = allStats.reduce((s: number, e: any) => s + e.contracts.confirmed, 0);
    const totalRevenue = allStats.reduce((s: number, e: any) => s + e.revenue, 0);
    const totalCancelRequested = allStats.reduce((s: number, e: any) => s + e.contracts.cancelRequested, 0);

    return {
      success: true,
      summary: {
        totalEvents: events.length,
        totalContracts,
        totalConfirmed,
        totalRevenue,
        totalCancelRequested,
        totalVendors,
        unapprovedVendors,
        totalCustomers,
      },
      events: allStats,
    };
  }
}
