// ============================================
// 계약 서비스 (Contracts Service)
// 계약 생성/조회/취소 로직
//
// 쉽게 말하면: 계약서 작성하고 관리하는 직원
// - 고객: 장바구니에서 계약 신청 → 계약 생성
// - 업체: 내 상품에 대한 계약 목록 확인
// - 계약금 = 상품가격 × 30% (depositRate)
// ============================================

import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { CreateContractDto } from './dto/create-contract.dto';
import { NotificationsService, NotificationType } from '../notifications/notifications.service';
import { ActivityLogsService } from '../activity-logs/activity-logs.service';

@Injectable()
export class ContractsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly activityLogs: ActivityLogsService,
  ) {}

  // 계약 생성 (장바구니 → 계약)
  // 여러 상품을 한번에 계약 (각 상품별로 개별 계약 생성)
  async createContracts(userId: string, dto: CreateContractDto) {
    // 고객 정보 조회
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }

    const contracts = [];

    for (const item of dto.items) {
      // 품목 정보 조회 (1뎁스) + 업체 정보 포함
      const product = await this.prisma.product.findUnique({
        where: { id: item.productId },
        include: { vendor: { select: { name: true, businessNumber: true } } },
      });

      if (!product) {
        throw new NotFoundException(`품목(${item.productId})을 찾을 수 없습니다`);
      }

      // 해당 행사의 계약금 비율 가져오기 (기본 30%)
      const event = await this.prisma.event.findUnique({
        where: { id: item.eventId },
        select: { depositRate: true },
      });
      const depositRate = event?.depositRate ?? 0.3;

      // 상세 품목(2뎁스)에서 가격 가져오기
      let price = 0;
      let productItemId: string | null = null;
      let productItemName: string | null = null;

      if (item.productItemId) {
        const productItem = await this.prisma.productItem.findUnique({
          where: { id: item.productItemId },
        });
        if (!productItem) {
          throw new NotFoundException(`상세 품목(${item.productItemId})을 찾을 수 없습니다`);
        }
        price = productItem.price;
        productItemId = productItem.id;
        productItemName = productItem.name;
      }

      // 계약금과 잔금 계산
      const depositAmount = Math.round(price * depositRate);
      const remainAmount = price - depositAmount;

      // 계약 생성 (품목/업체 정보를 스냅샷으로 함께 저장)
      const contract = await this.prisma.contract.create({
        data: {
          customerId: userId,
          customerName: user.name,
          customerPhone: dto.customerPhone ?? user.phone,
          customerAddress: dto.customerAddress,
          productId: item.productId,
          productItemId,
          productName: product.name,
          productItemName,
          vendorName: product.vendorName ?? product.vendor?.name ?? null,
          vendorBusinessNumber: product.vendor?.businessNumber ?? null,
          eventId: item.eventId,
          vendorId: product.vendorId ?? '',
          originalPrice: price,
          depositAmount,
          remainAmount,
        },
        include: {
          product: true,
          productItem: true,
        },
      });

      contracts.push(contract);
    }

    // 계약 생성 알림 → 업체 + 주관사에게 일괄 전송 (N건을 1개 알림으로 배치)
    try {
      // 업체별로 그룹핑하여 알림 발송
      const vendorGroups: Record<string, string[]> = {};
      for (const contract of contracts) {
        const vid = contract.vendorId;
        if (!vendorGroups[vid]) vendorGroups[vid] = [];
        vendorGroups[vid].push((contract as any).product?.name ?? '품목');
      }

      // 업체별 1개 알림 (빈 vendorId는 건너뛰기)
      for (const [vendorId, productNames] of Object.entries(vendorGroups)) {
        if (!vendorId) continue;
        await this.notifications.send({
          userId: vendorId,
          type: NotificationType.CONTRACT_CREATED,
          title: '새 계약이 들어왔습니다',
          body: productNames.length === 1
            ? `${user.name}님이 '${productNames[0]}'을(를) 계약했습니다.`
            : `${user.name}님이 '${productNames[0]}' 외 ${productNames.length - 1}건을 계약했습니다.`,
          data: { eventId: contracts[0].eventId },
        });
      }

      // 주관사에게 1개 알림
      const event = await this.prisma.event.findUnique({
        where: { id: contracts[0].eventId },
        select: { organizerId: true },
      });
      if (event) {
        const allNames = contracts.map((c) => (c as any).product?.name ?? '품목');
        await this.notifications.send({
          userId: event.organizerId,
          type: NotificationType.CONTRACT_CREATED,
          title: '새 계약이 발생했습니다',
          body: allNames.length === 1
            ? `${user.name}님이 '${allNames[0]}'을(를) 계약했습니다.`
            : `${user.name}님이 '${allNames[0]}' 외 ${allNames.length - 1}건을 계약했습니다.`,
          data: { eventId: contracts[0].eventId },
        });
      }
    } catch (e) {
      // 알림 전송 실패해도 계약 생성은 성공으로 처리
      console.error('알림 전송 실패:', e);
    }

    // 계약 생성 활동 로그 기록
    await this.activityLogs.log({
      userId,
      action: 'CONTRACT_CREATE',
      target: contracts[0]?.eventId,
      detail: `${user.name}이(가) ${contracts.length}건 계약 생성`,
    });

    // 계약 완료된 상품은 장바구니에서 제거
    for (const item of dto.items) {
      await this.prisma.cartItem.deleteMany({
        where: {
          userId,
          productId: item.productId,
          eventId: item.eventId,
        },
      });
    }

    return contracts;
  }

  // 고객의 계약 목록 조회 (행사/주관사/업체 정보 포함)
  async findByCustomer(userId: string, eventId?: string) {
    const where: any = { customerId: userId };
    if (eventId) where.eventId = eventId;

    return this.prisma.contract.findMany({
      where,
      include: {
        product: {
          include: {
            vendor: {
              select: { id: true, name: true, phone: true, representativeName: true, businessNumber: true, businessAddress: true },
            },
          },
        },
        productItem: true,
        event: {
          select: {
            id: true, title: true, siteName: true,
            organizer: { select: { id: true, name: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // 업체의 계약 목록 조회 (행사/주관사/고객 정보 포함)
  async findByVendor(vendorId: string, eventId?: string) {
    const where: any = { vendorId };
    if (eventId) where.eventId = eventId;

    return this.prisma.contract.findMany({
      where,
      include: {
        product: true,
        productItem: true,
        customer: {
          select: { id: true, name: true, phone: true, email: true },
        },
        event: {
          select: {
            id: true, title: true, siteName: true,
            organizer: { select: { id: true, name: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // 주관사용 - 행사별 전체 계약 목록
  async findByEvent(eventId: string) {
    return this.prisma.contract.findMany({
      where: { eventId },
      include: {
        product: true,
        productItem: true,
        customer: {
          select: { id: true, name: true, phone: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // 계약 상세 조회 (행사/주관사/업체 전체 정보 포함)
  async findOne(id: string) {
    const contract = await this.prisma.contract.findUnique({
      where: { id },
      include: {
        product: {
          include: {
            vendor: {
              select: { id: true, name: true, phone: true, representativeName: true, businessNumber: true, businessAddress: true },
            },
          },
        },
        productItem: true,
        customer: {
          select: { id: true, name: true, phone: true, email: true },
        },
        event: {
          select: {
            id: true, title: true, siteName: true, depositRate: true,
            organizer: { select: { id: true, name: true } },
          },
        },
        payments: true,
      },
    });

    if (!contract) {
      throw new NotFoundException('계약을 찾을 수 없습니다');
    }

    return contract;
  }

  // 계약 취소 요청 (고객이 호출)
  // CONFIRMED → CANCEL_REQUESTED 로 상태 변경 (바로 취소되지 않음)
  async cancel(contractId: string, userId: string) {
    const contract = await this.prisma.contract.findUnique({
      where: { id: contractId },
    });

    if (!contract) {
      throw new NotFoundException('계약을 찾을 수 없습니다');
    }

    // 본인 계약인지 확인 (고객만 취소 요청 가능)
    if (contract.customerId !== userId) {
      throw new BadRequestException('본인의 계약만 취소 요청할 수 있습니다');
    }

    // CONFIRMED 상태에서만 취소 요청 가능
    if (contract.status !== 'CONFIRMED') {
      throw new BadRequestException(
        '확정된 계약만 취소 요청할 수 있습니다 (현재 상태: ' + contract.status + ')',
      );
    }

    const updated = await this.prisma.contract.update({
      where: { id: contractId },
      data: { status: 'CANCEL_REQUESTED' },
      include: { product: true, customer: { select: { name: true } } },
    });

    // 취소 요청 알림 → 업체에게 전송
    await this.notifications.send({
      userId: contract.vendorId,
      type: NotificationType.CANCEL_REQUESTED,
      title: '계약 취소 요청이 들어왔습니다',
      body: `${updated.customer?.name}님이 '${updated.product?.name}' 계약 취소를 요청했습니다.`,
      data: { contractId },
    });

    // 취소 요청 활동 로그
    await this.activityLogs.log({
      userId,
      action: 'CONTRACT_CANCEL_REQUEST',
      target: contractId,
      detail: `${updated.customer?.name}이(가) '${updated.product?.name}' 계약 취소 요청`,
    });

    return updated;
  }

  // 취소 요청 승인 (업체가 호출)
  // CANCEL_REQUESTED → CANCELLED + 결제 환불 처리
  async approveCancel(contractId: string, vendorId: string) {
    const contract = await this.prisma.contract.findUnique({
      where: { id: contractId },
      include: { payments: true },
    });

    if (!contract) {
      throw new NotFoundException('계약을 찾을 수 없습니다');
    }

    // 해당 업체의 계약인지 확인
    if (contract.vendorId !== vendorId) {
      throw new BadRequestException('본인 상품의 계약만 처리할 수 있습니다');
    }

    // CANCEL_REQUESTED 상태에서만 승인 가능
    if (contract.status !== 'CANCEL_REQUESTED') {
      throw new BadRequestException('취소 요청 상태의 계약만 승인할 수 있습니다');
    }

    // 트랜잭션으로 계약 취소 + 결제 환불 동시 처리
    const updatedContract = await this.prisma.$transaction(async (tx) => {
      // 1. 계약 상태 → CANCELLED
      const updated = await tx.contract.update({
        where: { id: contractId },
        data: { status: 'CANCELLED' },
        include: { product: true },
      });

      // 2. 완료된 결제가 있으면 환불 처리
      await tx.payment.updateMany({
        where: {
          contractId,
          status: 'COMPLETED',
        },
        data: { status: 'REFUNDED' },
      });

      return updated;
    });

    // 취소 승인 알림 → 고객에게 전송
    await this.notifications.send({
      userId: contract.customerId,
      type: NotificationType.CANCEL_APPROVED,
      title: '계약 취소가 승인되었습니다',
      body: `'${updatedContract.product?.name}' 계약이 취소되었습니다. 결제금이 환불됩니다.`,
      data: { contractId },
    });

    // 취소 승인 활동 로그
    await this.activityLogs.log({
      userId: vendorId,
      action: 'CONTRACT_CANCEL_APPROVE',
      target: contractId,
      detail: `'${updatedContract.product?.name}' 계약 취소 승인 (환불 처리)`,
    });

    return updatedContract;
  }

  // 업체 직접 계약 취소 및 환불 (업체가 호출)
  // CONFIRMED 또는 PENDING → CANCELLED + 결제 환불 처리
  async vendorCancel(contractId: string, vendorId: string) {
    const contract = await this.prisma.contract.findUnique({
      where: { id: contractId },
      include: { payments: true },
    });

    if (!contract) {
      throw new NotFoundException('계약을 찾을 수 없습니다');
    }

    // 해당 업체의 계약인지 확인
    if (contract.vendorId !== vendorId) {
      throw new BadRequestException('본인 상품의 계약만 취소할 수 있습니다');
    }

    // 이미 취소된 계약은 처리 불가
    if (contract.status === 'CANCELLED') {
      throw new BadRequestException('이미 취소된 계약입니다');
    }

    // 트랜잭션으로 계약 취소 + 결제 환불 동시 처리
    const updatedContract = await this.prisma.$transaction(async (tx) => {
      // 1. 계약 상태 → CANCELLED
      const updated = await tx.contract.update({
        where: { id: contractId },
        data: { status: 'CANCELLED' },
        include: { product: true },
      });

      // 2. 완료된 결제가 있으면 환불 처리
      await tx.payment.updateMany({
        where: {
          contractId,
          status: 'COMPLETED',
        },
        data: { status: 'REFUNDED' },
      });

      return updated;
    });

    // 취소 알림 → 고객에게 전송
    await this.notifications.send({
      userId: contract.customerId,
      type: NotificationType.CANCEL_APPROVED,
      title: '계약이 취소되었습니다',
      body: `'${updatedContract.product?.name}' 계약이 업체에 의해 취소되었습니다. 결제금이 환불됩니다.`,
      data: { contractId, eventId: contract.eventId },
    });

    // 주관사에게도 취소 알림 전송
    const event = await this.prisma.event.findUnique({
      where: { id: contract.eventId },
      select: { organizerId: true },
    });
    if (event) {
      await this.notifications.send({
        userId: event.organizerId,
        type: NotificationType.CANCEL_APPROVED,
        title: '계약이 취소되었습니다',
        body: `'${updatedContract.product?.name}' 계약이 업체에 의해 취소되었습니다.`,
        data: { contractId, eventId: contract.eventId },
      });
    }

    return updatedContract;
  }

  // 취소 요청 거부 (업체가 호출)
  // CANCEL_REQUESTED → CONFIRMED (원래 상태로 복귀)
  async rejectCancel(contractId: string, vendorId: string) {
    const contract = await this.prisma.contract.findUnique({
      where: { id: contractId },
    });

    if (!contract) {
      throw new NotFoundException('계약을 찾을 수 없습니다');
    }

    // 해당 업체의 계약인지 확인
    if (contract.vendorId !== vendorId) {
      throw new BadRequestException('본인 상품의 계약만 처리할 수 있습니다');
    }

    // CANCEL_REQUESTED 상태에서만 거부 가능
    if (contract.status !== 'CANCEL_REQUESTED') {
      throw new BadRequestException('취소 요청 상태의 계약만 거부할 수 있습니다');
    }

    // CONFIRMED로 원복
    const updated = await this.prisma.contract.update({
      where: { id: contractId },
      data: { status: 'CONFIRMED' },
      include: { product: true },
    });

    // 취소 거부 알림 → 고객에게 전송
    await this.notifications.send({
      userId: contract.customerId,
      type: NotificationType.CANCEL_REJECTED,
      title: '계약 취소 요청이 거부되었습니다',
      body: `'${updated.product?.name}' 계약 취소 요청이 거부되어 계약이 유지됩니다.`,
      data: { contractId },
    });

    return updated;
  }
}
