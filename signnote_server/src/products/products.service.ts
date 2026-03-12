// ============================================
// 상품 서비스 (Products Service)
// Product(1뎁스) + ProductItem(2뎁스) 관리
// ============================================

import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import { CreateProductOrganizerDto } from './dto/create-product-organizer.dto';
import { CreateProductItemDto } from './dto/create-product-item.dto';
import { ActivityLogsService } from '../activity-logs/activity-logs.service';
import { NotificationsService, NotificationType } from '../notifications/notifications.service';

@Injectable()
export class ProductsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly activityLogs: ActivityLogsService,
    private readonly notifications: NotificationsService,
  ) {}

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Product (1뎁스) 관련
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // 행사별 품목 목록 조회 (2뎁스 포함)
  // vendorId가 전달되면 다른 업체의 참가비/수수료/가격 숨김
  async findByEvent(eventId: string, housingType?: string, vendorId?: string) {
    const products = await this.prisma.product.findMany({
      where: { eventId },
      include: {
        items: {
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { sortOrder: 'asc' },
    });

    // housingType 필터가 있으면 해당 타입 포함된 아이템만 + 빈 품목 제거
    let filtered = products;
    if (housingType) {
      filtered = products.map(p => ({
        ...p,
        items: p.items.filter(item => item.housingTypes.includes(housingType)),
      })).filter(p => p.items.length > 0); // 해당 타입 아이템이 없는 1뎁스 품목 제거
    }

    // 업체(VENDOR)가 조회할 때: 다른 업체의 참가비/수수료/가격 숨김
    if (vendorId) {
      return filtered.map(p => {
        if (p.vendorId === vendorId) return p; // 내 품목은 그대로 표시
        return {
          ...p,
          participationFee: 0,   // 다른 업체의 참가비 숨김
          commissionRate: 0,     // 다른 업체의 수수료 숨김
          items: p.items.map(item => ({
            ...item,
            price: 0,            // 다른 업체의 상세품목 가격 숨김
          })),
        };
      });
    }

    return filtered;
  }

  // 품목 상세 조회 (2뎁스 포함)
  async findOne(id: string) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: {
        vendor: {
          select: { id: true, name: true },
        },
        event: {
          select: { id: true, title: true },
        },
        items: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!product) {
      throw new NotFoundException('품목을 찾을 수 없습니다');
    }

    return product;
  }

  // 상품 등록 (업체) — 레거시 호환용
  async create(vendorId: string, dto: CreateProductDto) {
    return this.prisma.product.create({
      data: {
        name: dto.name,
        category: dto.category,
        eventId: dto.eventId,
        vendorId,
        vendorName: dto.vendorName,
        image: dto.image,
        commissionRate: dto.commissionRate ?? 0,
        depositRate: dto.depositRate ?? null,
        participationFee: dto.participationFee ?? 0,
      },
    });
  }

  // 품목 수정 (주관사/관리자)
  async update(id: string, dto: Partial<CreateProductDto>) {
    const product = await this.prisma.product.findUnique({ where: { id } });
    if (!product) {
      throw new NotFoundException('품목을 찾을 수 없습니다');
    }

    return this.prisma.product.update({
      where: { id },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.category && { category: dto.category }),
        ...(dto.image !== undefined && { image: dto.image }),
        ...(dto.commissionRate !== undefined && { commissionRate: dto.commissionRate }),
        ...((dto as any).depositRate !== undefined && { depositRate: (dto as any).depositRate }),
        ...((dto as any).paymentSchedule !== undefined && { paymentSchedule: (dto as any).paymentSchedule }),
        ...(dto.participationFee !== undefined && { participationFee: dto.participationFee }),
        ...((dto as any).feePaymentConfirmed !== undefined && { feePaymentConfirmed: (dto as any).feePaymentConfirmed }),
      },
    });
  }

  // 전체 품목 목록 조회 (주관사/관리자용, 2뎁스 포함)
  async findAll(eventId?: string, category?: string) {
    const where: any = {};
    if (eventId) where.eventId = eventId;
    if (category) where.category = category;

    return this.prisma.product.findMany({
      where,
      include: {
        vendor: { select: { id: true, name: true } },
        event: { select: { id: true, title: true } },
        items: {
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { sortOrder: 'asc' },
    });
  }

  // 업체가 등록한 품목 목록 (배정된 품목, 2뎁스 포함)
  async findByVendor(vendorId: string, eventId?: string) {
    const where: any = { vendorId };
    if (eventId) where.eventId = eventId;

    return this.prisma.product.findMany({
      where,
      include: {
        items: {
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // ── 주관사용: 품목 등록 (1뎁스) ──
  async createByOrganizer(organizerId: string, dto: CreateProductOrganizerDto) {
    const product = await this.prisma.product.create({
      data: {
        name: dto.name,
        category: dto.name,  // 품목명 = 카테고리
        eventId: dto.eventId,
        participationFee: dto.participationFee ?? 0,
        commissionRate: dto.commissionRate ?? 0,
        depositRate: dto.depositRate ?? null,  // 품목별 계약금 비율 (null = 행사 기본값)
        paymentSchedule: dto.paymentSchedule ?? undefined,  // 결제 일정 (null = 행사 기본값)
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

  // ── 업체용: 가용 품목 목록 (아직 업체 배정 안 된 품목들) ──
  async findAvailable(eventId: string) {
    return this.prisma.product.findMany({
      where: {
        eventId,
        vendorId: null,
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  // ── 업체용: 품목 선점 ──
  async claimProduct(productId: string, vendorId: string, vendorName: string) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
    });

    if (!product) {
      throw new NotFoundException('품목을 찾을 수 없습니다');
    }

    if (product.vendorId) {
      throw new BadRequestException('이미 다른 업체가 선점한 품목입니다');
    }

    const updated = await this.prisma.product.update({
      where: { id: productId },
      data: {
        vendorId,
        vendorName,
      },
    });

    await this.activityLogs.log({
      userId: vendorId,
      action: 'PRODUCT_CREATE',
      target: productId,
      detail: `품목 선점: ${product.name} (업체: ${vendorName})`,
    });

    // 주관사에게 업체 참여 알림 전송
    const event = await this.prisma.event.findUnique({
      where: { id: product.eventId },
      select: { organizerId: true, title: true },
    });
    if (event) {
      await this.notifications.send({
        userId: event.organizerId,
        type: NotificationType.VENDOR_JOINED,
        title: '업체가 품목에 참여했습니다',
        body: `${vendorName}이(가) '${product.name}'에 참여했습니다.`,
        data: { eventId: product.eventId, productId },
      });
    }

    return updated;
  }

  // ── 주관사용: 업체를 품목에 배정 ──
  async assignVendor(productId: string, vendorId: string, organizerId: string) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
    });

    if (!product) {
      throw new NotFoundException('품목을 찾을 수 없습니다');
    }

    const vendor = await this.prisma.user.findUnique({
      where: { id: vendorId },
      select: { id: true, name: true, role: true },
    });

    if (!vendor || vendor.role !== 'VENDOR') {
      throw new BadRequestException('유효한 협력업체가 아닙니다');
    }

    const updated = await this.prisma.product.update({
      where: { id: productId },
      data: {
        vendorId: vendor.id,
        vendorName: vendor.name,
      },
    });

    await this.activityLogs.log({
      userId: organizerId,
      action: 'PRODUCT_UPDATE',
      target: productId,
      detail: `업체 배정: ${product.name} → ${vendor.name}`,
    });

    return updated;
  }

  // ── 주관사용: 업체 참가 취소 ──
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

    // 업체가 등록한 상세 품목(2뎁스) 전부 삭제
    await this.prisma.productItem.deleteMany({
      where: { productId },
    });

    const updated = await this.prisma.product.update({
      where: { id: productId },
      data: {
        vendorId: null,
        vendorName: null,
      },
    });

    await this.activityLogs.log({
      userId: organizerId,
      action: 'PRODUCT_UPDATE',
      target: productId,
      detail: `업체 참가 취소: ${product.name} (업체: ${vendorName}) — 상세 품목 초기화`,
    });

    return updated;
  }

  // ── 품목 삭제 (주관사/관리자용) ──
  async deleteProduct(productId: string, userId: string) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
      include: { items: true },
    });

    if (!product) {
      throw new NotFoundException('품목을 찾을 수 없습니다');
    }

    // 하위 상세 품목(2뎁스) 먼저 삭제
    if (product.items.length > 0) {
      await this.prisma.productItem.deleteMany({
        where: { productId },
      });
    }

    // 1뎁스 품목 삭제
    await this.prisma.product.delete({
      where: { id: productId },
    });

    // 삭제 로그 기록
    await this.activityLogs.log({
      userId,
      action: 'PRODUCT_DELETE',
      target: productId,
      detail: `품목 삭제: ${product.name}`,
    });

    return { success: true };
  }

  // ── 품목 순서 변경 (주관사용) ──
  async reorderProducts(eventId: string, productIds: string[]) {
    // productIds 배열 순서대로 sortOrder를 0, 1, 2, ... 로 업데이트
    const updates = productIds.map((id, index) =>
      this.prisma.product.update({
        where: { id },
        data: { sortOrder: index },
      }),
    );

    await this.prisma.$transaction(updates);
    return { success: true };
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ProductItem (2뎁스) 관련
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // 상세 품목 목록 조회 (특정 1뎁스 하위)
  async findItemsByProduct(productId: string) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
    });
    if (!product) {
      throw new NotFoundException('품목을 찾을 수 없습니다');
    }

    return this.prisma.productItem.findMany({
      where: { productId },
      orderBy: { createdAt: 'asc' },
    });
  }

  // 상세 품목 등록 (업체가 2뎁스 패키지 추가)
  async createItem(productId: string, vendorId: string, dto: CreateProductItemDto) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
    });

    if (!product) {
      throw new NotFoundException('품목을 찾을 수 없습니다');
    }

    // 이 품목에 배정된 업체만 상세 품목 추가 가능
    if (product.vendorId !== vendorId) {
      throw new BadRequestException('이 품목에 배정된 업체만 상세 품목을 추가할 수 있습니다');
    }

    const item = await this.prisma.productItem.create({
      data: {
        productId,
        name: dto.name,
        housingTypes: dto.housingTypes,
        description: dto.description,
        price: dto.price,
        image: dto.image ?? (dto.images?.length ? dto.images[0] : undefined),
        images: dto.images ?? (dto.image ? [dto.image] : []),
      },
    });

    await this.activityLogs.log({
      userId: vendorId,
      action: 'PRODUCT_ITEM_CREATE',
      target: item.id,
      detail: `상세 품목 등록: ${product.name} > ${dto.name} (${dto.price}원)`,
    });

    // 주관사에게 품목 등록 알림 전송
    const event = await this.prisma.event.findUnique({
      where: { id: product.eventId },
      select: { organizerId: true },
    });
    if (event) {
      await this.notifications.send({
        userId: event.organizerId,
        type: NotificationType.PRODUCT_REGISTERED,
        title: '새 품목이 등록되었습니다',
        body: `${product.vendorName ?? '업체'}가 '${product.name}'에 '${dto.name}'을(를) 등록했습니다.`,
        data: { eventId: product.eventId, productId },
      });
    }

    return item;
  }

  // 상세 품목 수정
  async updateItem(itemId: string, vendorId: string, dto: Partial<CreateProductItemDto>) {
    const existingItem = await this.prisma.productItem.findUnique({
      where: { id: itemId },
      include: { product: true },
    });

    if (!existingItem) {
      throw new NotFoundException('상세 품목을 찾을 수 없습니다');
    }

    // 배정된 업체 또는 주관사/관리자만 수정 가능 (vendorId로 체크)
    if (existingItem.product.vendorId !== vendorId) {
      throw new BadRequestException('수정 권한이 없습니다');
    }

    const updated = await this.prisma.productItem.update({
      where: { id: itemId },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.housingTypes && { housingTypes: dto.housingTypes }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.price !== undefined && { price: dto.price }),
        ...(dto.image !== undefined && { image: dto.image }),
        ...(dto.images !== undefined && { images: dto.images }),
      },
    });

    // 주관사에게 품목 수정 알림 전송
    const event = await this.prisma.event.findUnique({
      where: { id: existingItem.product.eventId },
      select: { organizerId: true },
    });
    if (event) {
      await this.notifications.send({
        userId: event.organizerId,
        type: NotificationType.PRODUCT_UPDATED,
        title: '품목이 수정되었습니다',
        body: `${existingItem.product.vendorName ?? '업체'}가 '${existingItem.product.name}'의 '${existingItem.name}'을(를) 수정했습니다.`,
        data: { eventId: existingItem.product.eventId, productId: existingItem.productId },
      });
    }

    return updated;
  }

  // 상세 품목 삭제
  async deleteItem(itemId: string, userId: string) {
    const item = await this.prisma.productItem.findUnique({
      where: { id: itemId },
      include: { product: true },
    });

    if (!item) {
      throw new NotFoundException('상세 품목을 찾을 수 없습니다');
    }

    await this.prisma.productItem.delete({
      where: { id: itemId },
    });

    await this.activityLogs.log({
      userId,
      action: 'PRODUCT_ITEM_DELETE',
      target: itemId,
      detail: `상세 품목 삭제: ${item.product.name} > ${item.name}`,
    });

    return { success: true };
  }

  // 상세 품목 단건 조회
  async findOneItem(itemId: string) {
    const item = await this.prisma.productItem.findUnique({
      where: { id: itemId },
      include: {
        product: {
          select: { id: true, name: true, category: true, vendorName: true },
        },
      },
    });

    if (!item) {
      throw new NotFoundException('상세 품목을 찾을 수 없습니다');
    }

    return item;
  }
}
