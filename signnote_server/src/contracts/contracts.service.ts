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

@Injectable()
export class ContractsService {
  // 계약금 비율 (30%)
  private readonly DEPOSIT_RATE = 0.3;

  constructor(private readonly prisma: PrismaService) {}

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
      // 상품 정보 조회
      const product = await this.prisma.product.findUnique({
        where: { id: item.productId },
      });

      if (!product) {
        throw new NotFoundException(`상품(${item.productId})을 찾을 수 없습니다`);
      }

      // 계약금과 잔금 계산
      const depositAmount = Math.round(product.price * this.DEPOSIT_RATE);
      const remainAmount = product.price - depositAmount;

      // 계약 생성
      const contract = await this.prisma.contract.create({
        data: {
          customerId: userId,
          customerName: user.name,
          customerPhone: dto.customerPhone ?? user.phone,
          customerAddress: dto.customerAddress,
          productId: item.productId,
          eventId: item.eventId,
          vendorId: product.vendorId,
          originalPrice: product.price,
          depositAmount,
          remainAmount,
          // status는 기본값 PENDING (계약금 결제 대기)
        },
        include: {
          product: true,
        },
      });

      contracts.push(contract);
    }

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

  // 고객의 계약 목록 조회
  async findByCustomer(userId: string, eventId?: string) {
    const where: any = { customerId: userId };
    if (eventId) where.eventId = eventId;

    return this.prisma.contract.findMany({
      where,
      include: {
        product: true,       // 상품 정보
        event: {
          select: { id: true, title: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // 업체의 계약 목록 조회 (내 상품에 대한 계약)
  async findByVendor(vendorId: string, eventId?: string) {
    const where: any = { vendorId };
    if (eventId) where.eventId = eventId;

    return this.prisma.contract.findMany({
      where,
      include: {
        product: true,
        customer: {
          select: { id: true, name: true, phone: true },
        },
        event: {
          select: { id: true, title: true },
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
        customer: {
          select: { id: true, name: true, phone: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // 계약 상세 조회
  async findOne(id: string) {
    const contract = await this.prisma.contract.findUnique({
      where: { id },
      include: {
        product: true,
        customer: {
          select: { id: true, name: true, phone: true },
        },
        event: {
          select: { id: true, title: true },
        },
        payments: true,
      },
    });

    if (!contract) {
      throw new NotFoundException('계약을 찾을 수 없습니다');
    }

    return contract;
  }

  // 계약 취소
  async cancel(contractId: string, userId: string) {
    const contract = await this.prisma.contract.findUnique({
      where: { id: contractId },
    });

    if (!contract) {
      throw new NotFoundException('계약을 찾을 수 없습니다');
    }

    // 본인 계약인지 확인 (고객 또는 업체)
    if (contract.customerId !== userId && contract.vendorId !== userId) {
      throw new BadRequestException('본인의 계약만 취소할 수 있습니다');
    }

    // 이미 취소된 계약인지 확인
    if (contract.status === 'CANCELLED') {
      throw new BadRequestException('이미 취소된 계약입니다');
    }

    return this.prisma.contract.update({
      where: { id: contractId },
      data: { status: 'CANCELLED' },
    });
  }
}
