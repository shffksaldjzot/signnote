// ============================================
// 상품 서비스 (Products Service)
// 상품(품목) 데이터를 DB에서 조회/생성/수정하는 로직
// ============================================

import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';

@Injectable()
export class ProductsService {
  constructor(private readonly prisma: PrismaService) {}

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

  // 업체가 등록한 상품 목록
  async findByVendor(vendorId: string, eventId?: string) {
    const where: any = { vendorId };
    if (eventId) where.eventId = eventId;

    return this.prisma.product.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
  }
}
