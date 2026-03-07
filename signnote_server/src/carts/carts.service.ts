// ============================================
// 장바구니 서비스 (Carts Service)
// 장바구니 조회/추가/삭제 로직
//
// 쉽게 말하면: 마트에서 카트에 물건을 담고 빼는 것
// - 카트 보기 (getCartItems)
// - 물건 담기 (addItem)
// - 물건 빼기 (removeItem)
// - 카트 비우기 (clearCart)
// ============================================

import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { AddCartItemDto } from './dto/add-cart-item.dto';

@Injectable()
export class CartsService {
  constructor(private readonly prisma: PrismaService) {}

  // 내 장바구니 조회 (행사별)
  // 상품 정보도 함께 가져옴
  async getCartItems(userId: string, eventId?: string) {
    const where: any = { userId };
    if (eventId) where.eventId = eventId;

    return this.prisma.cartItem.findMany({
      where,
      include: {
        product: true,       // 1뎁스 품목 정보
        productItem: true,   // 2뎁스 상세 품목 정보 (가격 포함)
        event: {
          select: { id: true, title: true },  // 행사 이름
        },
      },
      orderBy: { addedAt: 'desc' },  // 최근 담은 순
    });
  }

  // 장바구니에 상품 추가
  async addItem(userId: string, dto: AddCartItemDto) {
    // productItemId가 있으면 상세 품목 기준, 없으면 1뎁스 기준으로 중복 체크
    const whereCondition: any = {
      userId,
      productId: dto.productId,
      eventId: dto.eventId,
    };
    if (dto.productItemId) {
      whereCondition.productItemId = dto.productItemId;
    }

    const existing = await this.prisma.cartItem.findFirst({
      where: whereCondition,
    });

    if (existing) {
      throw new ConflictException('이미 장바구니에 담긴 상품입니다');
    }

    // 상품이 실제로 존재하는지 확인
    const product = await this.prisma.product.findUnique({
      where: { id: dto.productId },
    });

    if (!product) {
      throw new NotFoundException('상품을 찾을 수 없습니다');
    }

    return this.prisma.cartItem.create({
      data: {
        userId,
        productId: dto.productId,
        productItemId: dto.productItemId ?? null,
        eventId: dto.eventId,
        quantity: dto.quantity ?? 1,
      },
      include: {
        product: true,
        productItem: true,
      },
    });
  }

  // 장바구니에서 상품 제거
  async removeItem(userId: string, cartItemId: string) {
    const item = await this.prisma.cartItem.findFirst({
      where: { id: cartItemId, userId },
    });

    if (!item) {
      throw new NotFoundException('장바구니 항목을 찾을 수 없습니다');
    }

    return this.prisma.cartItem.delete({
      where: { id: cartItemId },
    });
  }

  // 장바구니 전체 비우기 (행사별)
  async clearCart(userId: string, eventId: string) {
    return this.prisma.cartItem.deleteMany({
      where: { userId, eventId },
    });
  }

  // 장바구니 상품 개수
  async getCartCount(userId: string, eventId?: string) {
    const where: any = { userId };
    if (eventId) where.eventId = eventId;

    return this.prisma.cartItem.count({ where });
  }
}
