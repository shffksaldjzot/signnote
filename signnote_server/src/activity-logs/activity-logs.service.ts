// ============================================
// 활동 로그 서비스 (ActivityLogs Service)
//
// 사용자 행동을 기록하는 서비스
// 다른 모듈에서 this.activityLogs.log(...) 호출하면 기록됨
// ============================================

import { Injectable } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';

// 로그 종류 상수
export const ActivityAction = {
  // 인증
  LOGIN: 'LOGIN',
  REGISTER: 'REGISTER',
  LOGOUT: 'LOGOUT',
  // 행사
  EVENT_CREATE: 'EVENT_CREATE',
  EVENT_UPDATE: 'EVENT_UPDATE',
  EVENT_ENTER: 'EVENT_ENTER',
  // 상품
  PRODUCT_CREATE: 'PRODUCT_CREATE',
  PRODUCT_UPDATE: 'PRODUCT_UPDATE',
  // 장바구니
  CART_ADD: 'CART_ADD',
  CART_REMOVE: 'CART_REMOVE',
  // 계약
  CONTRACT_CREATE: 'CONTRACT_CREATE',
  CONTRACT_CANCEL_REQUEST: 'CONTRACT_CANCEL_REQUEST',
  CONTRACT_CANCEL_APPROVE: 'CONTRACT_CANCEL_APPROVE',
  CONTRACT_CANCEL_REJECT: 'CONTRACT_CANCEL_REJECT',
  // 결제
  PAYMENT_CREATE: 'PAYMENT_CREATE',
  PAYMENT_REFUND: 'PAYMENT_REFUND',
  // 정산
  SETTLEMENT_TRANSFER: 'SETTLEMENT_TRANSFER',
  SETTLEMENT_COMPLETE: 'SETTLEMENT_COMPLETE',
};

@Injectable()
export class ActivityLogsService {
  constructor(private readonly prisma: PrismaService) {}

  // 활동 로그 기록
  async log(params: {
    userId?: string;
    action: string;
    target?: string;
    detail?: string;
    ipAddress?: string;
  }) {
    return this.prisma.activityLog.create({
      data: {
        userId: params.userId,
        action: params.action,
        target: params.target,
        detail: params.detail,
        ipAddress: params.ipAddress,
      },
    });
  }

  // 로그 목록 조회 (주관사/관리자용)
  async findAll(options?: {
    action?: string;
    userId?: string;
    limit?: number;
  }) {
    const where: any = {};
    if (options?.action) where.action = options.action;
    if (options?.userId) where.userId = options.userId;

    return this.prisma.activityLog.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: options?.limit ?? 100,
    });
  }
}
