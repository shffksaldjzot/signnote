// ============================================
// 알림 서비스 (Notifications Service)
//
// 3가지 알림 채널을 관리:
//   1. DB 저장 — 앱 내 알림 목록 (항상 동작)
//   2. FCM 푸시 — 앱 푸시 알림 (키 설정 시 동작)
//   3. 카카오 알림톡 — 문자 알림 (키 설정 시 동작)
//
// 키가 없으면 로그만 남기고 에러 없이 넘어감
// ============================================

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../common/prisma.service';

// 알림 종류 상수
export const NotificationType = {
  CONTRACT_CREATED: 'CONTRACT_CREATED',           // 계약 생성됨
  CONTRACT_CONFIRMED: 'CONTRACT_CONFIRMED',       // 계약 확정됨
  CANCEL_REQUESTED: 'CANCEL_REQUESTED',           // 취소 요청됨
  CANCEL_APPROVED: 'CANCEL_APPROVED',             // 취소 승인됨
  CANCEL_REJECTED: 'CANCEL_REJECTED',             // 취소 거부됨
  PAYMENT_COMPLETED: 'PAYMENT_COMPLETED',         // 결제 완료
  PAYMENT_REFUNDED: 'PAYMENT_REFUNDED',           // 결제 환불됨
  EVENT_CREATED: 'EVENT_CREATED',                 // 행사 생성됨
  VENDOR_JOINED: 'VENDOR_JOINED',                 // 업체 참여
  PRODUCT_REGISTERED: 'PRODUCT_REGISTERED',       // 품목 등록됨
  PRODUCT_UPDATED: 'PRODUCT_UPDATED',             // 품목 수정됨
};

// 알림 전송 요청 데이터
interface SendNotificationParams {
  userId: string;       // 받는 사용자 ID
  type: string;         // 알림 종류
  title: string;        // 알림 제목
  body: string;         // 알림 내용
  data?: any;           // 추가 데이터 (계약ID 등)
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger('NotificationsService');

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  // ── 알림 전송 (DB 저장 + FCM + 카카오) ──
  async send(params: SendNotificationParams) {
    const { userId, type, title, body, data } = params;

    // 1. DB에 알림 기록 저장 (항상 실행)
    const notification = await this.prisma.notification.create({
      data: { userId, type, title, body, data },
    });

    // 2. FCM 푸시 알림 (키가 있으면 전송)
    await this.sendFcmPush(userId, title, body, data);

    // 3. 카카오 알림톡 (키가 있으면 전송)
    await this.sendKakaoAlimtalk(userId, title, body);

    return notification;
  }

  // ── 여러 사용자에게 알림 전송 ──
  async sendToMany(userIds: string[], type: string, title: string, body: string, data?: any) {
    const results = [];
    for (const userId of userIds) {
      const result = await this.send({ userId, type, title, body, data });
      results.push(result);
    }
    return results;
  }

  // ── 내 알림 목록 조회 ──
  async findByUser(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,  // 최근 50개만
    });
  }

  // ── 알림 읽음 처리 ──
  async markAsRead(notificationId: string, userId: string) {
    return this.prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: { isRead: true },
    });
  }

  // ── 전체 읽음 처리 ──
  async markAllAsRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
  }

  // ── 특정 행사의 알림 목록 (data.eventId로 필터) ──
  async findByEvent(userId: string, eventId: string) {
    const notifications = await this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });

    // data JSON 안의 eventId로 필터링
    return notifications.filter((n) => (n.data as any)?.eventId === eventId);
  }

  // ── 안 읽은 알림 개수 ──
  async getUnreadCount(userId: string) {
    return this.prisma.notification.count({
      where: { userId, isRead: false },
    });
  }

  // ── 행사별 안 읽은 알림 개수 (주관사용) ──
  async getUnreadCountByEvents(userId: string) {
    // data JSON에 eventId가 포함된 알림을 행사별로 집계
    const unreadNotifications = await this.prisma.notification.findMany({
      where: { userId, isRead: false },
      select: { data: true },
    });

    const eventCounts: Record<string, number> = {};
    for (const n of unreadNotifications) {
      const eventId = (n.data as any)?.eventId;
      if (eventId) {
        eventCounts[eventId] = (eventCounts[eventId] || 0) + 1;
      }
    }
    return eventCounts;
  }

  // ── FCM 토큰 등록/갱신 ──
  async registerFcmToken(userId: string, fcmToken: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });
  }

  // ============================================
  // FCM 푸시 알림 전송
  // Firebase 서비스 계정 키가 .env에 설정되어 있어야 동작
  // 키 없으면 로그만 남기고 넘어감
  // ============================================
  private async sendFcmPush(userId: string, title: string, body: string, data?: any) {
    const fcmKey = this.config.get<string>('FCM_SERVER_KEY');

    if (!fcmKey) {
      this.logger.debug(`[FCM 미설정] 알림 스킵 → ${title}`);
      return;
    }

    try {
      // 사용자의 FCM 토큰 가져오기
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { fcmToken: true },
      });

      if (!user?.fcmToken) {
        this.logger.debug(`[FCM] 토큰 없음 → userId: ${userId}`);
        return;
      }

      // FCM HTTP v1 API로 푸시 전송
      // TODO: 실제 FCM 키 설정 후 활성화
      const response = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `key=${fcmKey}`,
        },
        body: JSON.stringify({
          to: user.fcmToken,
          notification: { title, body },
          data: data ?? {},
        }),
      });

      if (response.ok) {
        this.logger.log(`[FCM] 전송 성공 → ${title}`);
      } else {
        this.logger.warn(`[FCM] 전송 실패 → ${response.status}`);
      }
    } catch (error) {
      this.logger.error(`[FCM] 전송 오류 → ${error}`);
    }
  }

  // ============================================
  // 카카오 알림톡 전송
  // 카카오 비즈메시지 API 키가 .env에 설정되어 있어야 동작
  // 키 없으면 로그만 남기고 넘어감
  // ============================================
  private async sendKakaoAlimtalk(userId: string, title: string, body: string) {
    const kakaoApiKey = this.config.get<string>('KAKAO_ALIMTALK_API_KEY');
    const kakaoPfId = this.config.get<string>('KAKAO_ALIMTALK_PF_ID');

    if (!kakaoApiKey || !kakaoPfId) {
      this.logger.debug(`[카카오 알림톡 미설정] 알림 스킵 → ${title}`);
      return;
    }

    try {
      // 사용자 전화번호 가져오기
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { phone: true },
      });

      if (!user?.phone) {
        this.logger.debug(`[카카오] 전화번호 없음 → userId: ${userId}`);
        return;
      }

      // TODO: 실제 카카오 비즈메시지 API 연동
      // 현재는 로그만 남김
      this.logger.log(`[카카오 알림톡] 전송 예정 → ${user.phone}: ${title}`);

      // 실제 구현 시:
      // const response = await fetch('https://api-alimtalk.kakao.com/v2/sender/send', {
      //   method: 'POST',
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': `Bearer ${kakaoApiKey}`,
      //   },
      //   body: JSON.stringify({
      //     pfId: kakaoPfId,
      //     templateId: '템플릿ID',
      //     recipientNo: user.phone,
      //     templateParameter: { title, body },
      //   }),
      // });
    } catch (error) {
      this.logger.error(`[카카오] 전송 오류 → ${error}`);
    }
  }
}
