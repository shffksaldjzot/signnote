// ============================================
// 결제 서비스 (Payments Service)
// 결제 생성/조회/환불 로직
//
// 쉽게 말하면: 결제 처리를 담당하는 직원
// - 고객: 계약금 결제 → 계약 확정
// - 테스트 모드: PG 없이 바로 결제 완료 처리
// - 나중에: PG사 SDK 연동하면 실제 결제 처리
// ============================================

import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { SettlementsService } from '../settlements/settlements.service';
import { NotificationsService, NotificationType } from '../notifications/notifications.service';

@Injectable()
export class PaymentsService {
  // 테스트 모드 (PG 연동 전까지 true)
  // true면 결제 요청 시 바로 완료 처리
  private readonly TEST_MODE = true;

  constructor(
    private readonly prisma: PrismaService,
    private readonly settlements: SettlementsService,
    private readonly notifications: NotificationsService,
  ) {}

  // 결제 생성 (계약 → 결제)
  // 계약의 계약금(depositAmount)만큼 결제 레코드 생성
  async createPayment(userId: string, dto: CreatePaymentDto) {
    // 계약 조회
    const contract = await this.prisma.contract.findUnique({
      where: { id: dto.contractId },
      include: { product: true },
    });

    if (!contract) {
      throw new NotFoundException('계약을 찾을 수 없습니다');
    }

    // 본인 계약인지 확인
    if (contract.customerId !== userId) {
      throw new BadRequestException('본인의 계약만 결제할 수 있습니다');
    }

    // 이미 결제된 계약인지 확인
    if (contract.status === 'CONFIRMED') {
      throw new BadRequestException('이미 결제 완료된 계약입니다');
    }

    // 취소된 계약인지 확인
    if (contract.status === 'CANCELLED') {
      throw new BadRequestException('취소된 계약은 결제할 수 없습니다');
    }

    // 이미 진행 중인 결제가 있는지 확인
    const existingPayment = await this.prisma.payment.findFirst({
      where: {
        contractId: dto.contractId,
        status: { in: ['PENDING', 'COMPLETED'] },
      },
    });

    if (existingPayment) {
      throw new BadRequestException('이미 결제가 진행 중이거나 완료되었습니다');
    }

    // 테스트 모드: PG 없이 바로 결제 완료 처리
    if (this.TEST_MODE) {
      // 결제 레코드 생성 (바로 COMPLETED)
      const payment = await this.prisma.payment.create({
        data: {
          contractId: dto.contractId,
          amount: contract.depositAmount,
          method: dto.method ?? 'CARD',
          status: 'COMPLETED',
          paidAt: new Date(),
          pgTransactionId: `TEST_${Date.now()}`, // 테스트 거래번호
        },
        include: { contract: true },
      });

      // 계약 상태를 CONFIRMED(확정)으로 변경
      await this.prisma.contract.update({
        where: { id: dto.contractId },
        data: { status: 'CONFIRMED' },
      });

      // 정산 레코드 자동 생성 (수수료 계산)
      await this.settlements.createFromContract(dto.contractId);

      // 결제 완료 알림 → 고객에게
      await this.notifications.send({
        userId,
        type: NotificationType.PAYMENT_COMPLETED,
        title: '결제가 완료되었습니다',
        body: `'${contract.product?.name}' 계약금 ${contract.depositAmount.toLocaleString()}원 결제 완료`,
        data: { contractId: dto.contractId, paymentId: payment.id },
      });

      return payment;
    }

    // 실제 PG 연동 시: PENDING 상태로 생성 → Webhook에서 COMPLETED로 변경
    const payment = await this.prisma.payment.create({
      data: {
        contractId: dto.contractId,
        amount: contract.depositAmount,
        method: dto.method ?? 'CARD',
        status: 'PENDING',
      },
      include: { contract: true },
    });

    return payment;
  }

  // PG 결제 완료 콜백 (Webhook)
  // 나중에 PG사에서 결제 완료되면 이 엔드포인트로 알려줌
  async handleWebhook(pgTransactionId: string, status: string) {
    // PG 거래번호로 결제 조회
    const payment = await this.prisma.payment.findFirst({
      where: { pgTransactionId },
    });

    if (!payment) {
      throw new NotFoundException('결제 정보를 찾을 수 없습니다');
    }

    if (status === 'COMPLETED') {
      // 결제 완료 처리
      await this.prisma.payment.update({
        where: { id: payment.id },
        data: {
          status: 'COMPLETED',
          paidAt: new Date(),
        },
      });

      // 계약 상태를 CONFIRMED로 변경
      await this.prisma.contract.update({
        where: { id: payment.contractId },
        data: { status: 'CONFIRMED' },
      });

      // 정산 레코드 자동 생성
      await this.settlements.createFromContract(payment.contractId);
    } else if (status === 'FAILED') {
      // 결제 실패 처리
      await this.prisma.payment.update({
        where: { id: payment.id },
        data: { status: 'FAILED' },
      });
    }

    return { success: true };
  }

  // 내 결제 목록 조회
  async findMyPayments(userId: string, eventId?: string) {
    // 내 계약에 연결된 결제만 조회
    const where: any = {
      contract: { customerId: userId },
    };
    if (eventId) {
      where.contract.eventId = eventId;
    }

    return this.prisma.payment.findMany({
      where,
      include: {
        contract: {
          include: {
            product: true,
            event: { select: { id: true, title: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // 결제 상세 조회
  async findOne(id: string, userId: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id },
      include: {
        contract: {
          include: {
            product: true,
            event: { select: { id: true, title: true } },
          },
        },
      },
    });

    if (!payment) {
      throw new NotFoundException('결제 정보를 찾을 수 없습니다');
    }

    // 본인 결제인지 확인
    if (payment.contract.customerId !== userId) {
      throw new BadRequestException('본인의 결제만 조회할 수 있습니다');
    }

    return payment;
  }

  // 환불 요청
  async requestRefund(paymentId: string, userId: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
      include: { contract: true },
    });

    if (!payment) {
      throw new NotFoundException('결제 정보를 찾을 수 없습니다');
    }

    // 본인 결제인지 확인
    if (payment.contract.customerId !== userId) {
      throw new BadRequestException('본인의 결제만 환불할 수 있습니다');
    }

    // 완료된 결제만 환불 가능
    if (payment.status !== 'COMPLETED') {
      throw new BadRequestException('완료된 결제만 환불할 수 있습니다');
    }

    // 결제 상태를 REFUNDED로 변경
    const updatedPayment = await this.prisma.payment.update({
      where: { id: paymentId },
      data: { status: 'REFUNDED' },
    });

    // 계약 상태를 CANCELLED로 변경
    await this.prisma.contract.update({
      where: { id: payment.contractId },
      data: { status: 'CANCELLED' },
    });

    return updatedPayment;
  }
}
