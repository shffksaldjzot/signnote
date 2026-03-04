// ============================================
// 정산 서비스 (Settlements Service)
//
// 쉽게 말하면: 고객이 낸 돈을 업체에게 나눠주는 담당
//   1. 계약 확정(CONFIRMED) → 정산 레코드 자동 생성
//   2. 수수료 계산 (상품의 commissionRate 적용)
//   3. 주관사가 '지급' 버튼 → 정산 상태 변경
//   4. 실제 은행 송금은 나중에 PG 지급대행 API 연동
//
// 정산 금액 계산:
//   결제 금액 (depositAmount) - 수수료(fee) = 업체 지급액
//   fee = depositAmount × commissionRate
// ============================================

import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';

@Injectable()
export class SettlementsService {
  private readonly logger = new Logger('SettlementsService');

  constructor(private readonly prisma: PrismaService) {}

  // ── 정산 레코드 자동 생성 (결제 완료 시 호출) ──
  // 계약 확정 → 정산 대기 상태로 생성
  async createFromContract(contractId: string) {
    // 계약 + 상품 정보 조회
    const contract = await this.prisma.contract.findUnique({
      where: { id: contractId },
      include: { product: true },
    });

    if (!contract) {
      throw new NotFoundException('계약을 찾을 수 없습니다');
    }

    // 이미 정산이 있는지 확인
    const existing = await this.prisma.settlement.findUnique({
      where: { contractId },
    });

    if (existing) {
      this.logger.warn(`이미 정산 존재: contractId=${contractId}`);
      return existing;
    }

    // 수수료 계산
    const commissionRate = contract.product?.commissionRate ?? 0;
    const fee = Math.round(contract.depositAmount * commissionRate);
    const amount = contract.depositAmount - fee;  // 업체 지급액

    // 정산 레코드 생성
    const settlement = await this.prisma.settlement.create({
      data: {
        contractId,
        vendorId: contract.vendorId,
        amount,     // 업체 지급액
        fee,        // 수수료
        status: 'PENDING',  // 대기 상태
      },
    });

    this.logger.log(
      `정산 생성: ${contract.depositAmount}원 → 수수료 ${fee}원, 지급액 ${amount}원`,
    );

    return settlement;
  }

  // ── 업체별 정산 목록 조회 ──
  async findByVendor(vendorId: string) {
    return this.prisma.settlement.findMany({
      where: { vendorId },
      include: {
        contract: {
          include: {
            product: { select: { id: true, name: true, category: true } },
            customer: { select: { id: true, name: true } },
            event: { select: { id: true, title: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // ── 전체 정산 목록 (주관사/관리자용) ──
  async findAll(status?: string, eventId?: string) {
    const where: any = {};
    if (status) where.status = status;
    if (eventId) where.contract = { eventId };

    return this.prisma.settlement.findMany({
      where,
      include: {
        contract: {
          include: {
            product: { select: { id: true, name: true } },
            customer: { select: { id: true, name: true } },
            event: { select: { id: true, title: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // ── 정산 상세 조회 ──
  async findOne(id: string) {
    const settlement = await this.prisma.settlement.findUnique({
      where: { id },
      include: {
        contract: {
          include: {
            product: true,
            customer: { select: { id: true, name: true, phone: true } },
            event: { select: { id: true, title: true } },
          },
        },
      },
    });

    if (!settlement) {
      throw new NotFoundException('정산 정보를 찾을 수 없습니다');
    }

    return settlement;
  }

  // ── 정산 지급 처리 (주관사가 실행) ──
  // PENDING → TRANSFERRED (송금 완료)
  async transfer(id: string) {
    const settlement = await this.prisma.settlement.findUnique({
      where: { id },
    });

    if (!settlement) {
      throw new NotFoundException('정산 정보를 찾을 수 없습니다');
    }

    if (settlement.status !== 'PENDING') {
      throw new BadRequestException('대기 상태의 정산만 지급할 수 있습니다');
    }

    // TODO: 실제 PG 지급대행 API 연동 시 여기에 송금 로직 추가
    // 현재는 상태만 변경
    this.logger.log(`[정산 지급] ${settlement.amount}원 → vendorId: ${settlement.vendorId}`);

    return this.prisma.settlement.update({
      where: { id },
      data: {
        status: 'TRANSFERRED',
        transferDate: new Date(),
      },
    });
  }

  // ── 정산 완료 처리 ──
  // TRANSFERRED → COMPLETED
  async complete(id: string) {
    const settlement = await this.prisma.settlement.findUnique({
      where: { id },
    });

    if (!settlement) {
      throw new NotFoundException('정산 정보를 찾을 수 없습니다');
    }

    if (settlement.status !== 'TRANSFERRED') {
      throw new BadRequestException('송금된 정산만 완료 처리할 수 있습니다');
    }

    return this.prisma.settlement.update({
      where: { id },
      data: { status: 'COMPLETED' },
    });
  }

  // ── 업체별 정산 요약 (합계) ──
  async getVendorSummary(vendorId: string) {
    const settlements = await this.prisma.settlement.findMany({
      where: { vendorId },
    });

    const total = settlements.length;
    const pending = settlements.filter((s) => s.status === 'PENDING');
    const transferred = settlements.filter((s) => s.status === 'TRANSFERRED');
    const completed = settlements.filter((s) => s.status === 'COMPLETED');

    return {
      totalCount: total,
      pendingCount: pending.length,
      pendingAmount: pending.reduce((sum, s) => sum + s.amount, 0),
      transferredCount: transferred.length,
      transferredAmount: transferred.reduce((sum, s) => sum + s.amount, 0),
      completedCount: completed.length,
      completedAmount: completed.reduce((sum, s) => sum + s.amount, 0),
      totalFee: settlements.reduce((sum, s) => sum + s.fee, 0),
    };
  }
}
