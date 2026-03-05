// ============================================
// 상품 서비스 (Products Service)
// 상품(품목) 데이터를 DB에서 조회/생성/수정하는 로직
// ============================================

import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import { CreateProductOrganizerDto } from './dto/create-product-organizer.dto';
import { ActivityLogsService } from '../activity-logs/activity-logs.service';

@Injectable()
export class ProductsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly activityLogs: ActivityLogsService,
  ) {}

  // 행사별 상품 목록 조회 (카테고리별 그룹핑)
  async findByEvent(eventId: string, housingType?: string) {
    const where: any = { eventId };
    // 평형(타입) 필터가 있으면 해당 타입 포함된 상품만
    if (housingType) {
      where.housingTypes = { has: housingType };
    }

    return this.prisma.product.findMany({
      where,
      orderBy: { category: 'asc' },  // 카테고리 순 정렬
    });
  }

  // 상품 상세 조회
  async findOne(id: string) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: {
        vendor: {
          select: { id: true, name: true },  // 업체 정보
        },
        event: {
          select: { id: true, title: true },  // 행사 정보
        },
      },
    });

    if (!product) {
      throw new NotFoundException('상품을 찾을 수 없습니다');
    }

    return product;
  }

  // 상품 등록 (업체)
  async create(vendorId: string, dto: CreateProductDto) {
    return this.prisma.product.create({
      data: {
        name: dto.name,
        category: dto.category,
        eventId: dto.eventId,
        vendorId,
        vendorName: dto.vendorName,
        housingTypes: dto.housingTypes,
        image: dto.image,
        description: dto.description,
        price: dto.price,
        commissionRate: dto.commissionRate ?? 0,
        participationFee: dto.participationFee ?? 0,
      },
    });
  }

  // 상품 수정
  async update(id: string, dto: Partial<CreateProductDto>) {
    const product = await this.prisma.product.findUnique({ where: { id } });
    if (!product) {
      throw new NotFoundException('상품을 찾을 수 없습니다');
    }

    return this.prisma.product.update({
      where: { id },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.category && { category: dto.category }),
        ...(dto.housingTypes && { housingTypes: dto.housingTypes }),
        ...(dto.image !== undefined && { image: dto.image }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.price !== undefined && { price: dto.price }),
        ...(dto.commissionRate !== undefined && { commissionRate: dto.commissionRate }),
        ...(dto.participationFee !== undefined && { participationFee: dto.participationFee }),
      },
    });
  }

  // 전체 상품 목록 조회 (주관사/관리자용)
  // eventId, category로 필터 가능
  async findAll(eventId?: string, category?: string) {
    const where: any = {};
    if (eventId) where.eventId = eventId;
    if (category) where.category = category;

    return this.prisma.product.findMany({
      where,
      include: {
        vendor: { select: { id: true, name: true } },
        event: { select: { id: true, title: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // 업체가 등록한 상품 목록
  async findByVendor(vendorId: string, eventId?: string) {
    const where: any = { vendorId };
    if (eventId) where.eventId = eventId;

    return this.prisma.product.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
  }

  // ── 주관사용: 품목 등록 (vendorId 없이) ──
  async createByOrganizer(organizerId: string, dto: CreateProductOrganizerDto) {
    const product = await this.prisma.product.create({
      data: {
        name: dto.name,
        category: dto.name,  // 품목명 = 카테고리 (주관사가 등록하는 품목은 카테고리 자체)
        eventId: dto.eventId,
        // vendorId는 null (아직 업체가 선점하지 않음)
        participationFee: dto.participationFee ?? 0,
        commissionRate: dto.commissionRate ?? 0,
        image: dto.image,
      },
    });

    // 품목 등록 로그
    await this.activityLogs.log({
      userId: organizerId,
      action: 'PRODUCT_CREATE',
      target: product.id,
      detail: `품목 등록: ${dto.name}`,
    });

    return product;
  }

  // ── 업체용: 가용 품목 목록 (아직 선점 안 된 품목들) ──
  async findAvailable(eventId: string) {
    return this.prisma.product.findMany({
      where: {
        eventId,
        vendorId: null,  // 아직 업체가 없는 품목만
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  // ── 업체용: 품목 선점 ──
  // 업체가 품목을 선택하면 vendorId를 채워서 선점 처리
  async claimProduct(productId: string, vendorId: string, vendorName: string) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
    });

    if (!product) {
      throw new NotFoundException('품목을 찾을 수 없습니다');
    }

    // 이미 다른 업체가 선점했으면 에러
    if (product.vendorId) {
      throw new BadRequestException('이미 다른 업체가 선점한 품목입니다');
    }

    // 1행사 1품목 제한: 같은 행사에서 이미 품목을 선점한 업체는 추가 선점 불가
    const existingClaim = await this.prisma.product.findFirst({
      where: {
        eventId: product.eventId,
        vendorId,
      },
    });
    if (existingClaim) {
      throw new BadRequestException(
        `이미 이 행사에서 "${existingClaim.name}" 품목으로 참여 중입니다. 한 행사에 하나의 품목만 참여할 수 있습니다.`,
      );
    }

    const updated = await this.prisma.product.update({
      where: { id: productId },
      data: {
        vendorId,
        vendorName,
      },
    });

    // 품목 선점 로그
    await this.activityLogs.log({
      userId: vendorId,
      action: 'PRODUCT_CREATE',
      target: productId,
      detail: `품목 선점: ${product.name} (업체: ${vendorName})`,
    });

    return updated;
  }

  // ── 주관사용: 업체 참가 취소 (품목에서 업체 해제) ──
  async unclaimProduct(productId: string, organizerId: string) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
    });

    if (!product) {
      throw new NotFoundException('품목을 찾을 수 없습니다');
    }

    if (!product.vendorId) {
      throw new BadRequestException('이미 업체가 배정되어 있지 않은 품목입니다');
    }

    const vendorName = product.vendorName || '알 수 없음';

    const updated = await this.prisma.product.update({
      where: { id: productId },
      data: {
        vendorId: null,
        vendorName: null,
      },
    });

    // 참가 취소 로그
    await this.activityLogs.log({
      userId: organizerId,
      action: 'PRODUCT_UPDATE',
      target: productId,
      detail: `업체 참가 취소: ${product.name} (업체: ${vendorName})`,
    });

    return updated;
  }
}
