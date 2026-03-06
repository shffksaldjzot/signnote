// ============================================
// 상품 컨트롤러 (Products Controller)
//
// API 목록 — Product (1뎁스):
//   GET    /api/v1/products                     → 전체 품목 목록 (주관사/관리자)
//   GET    /api/v1/events/:eventId/products     → 행사별 품목 목록
//   GET    /api/v1/events/:eventId/products/available → 가용 품목 목록
//   GET    /api/v1/products/:id                 → 품목 상세
//   POST   /api/v1/products                     → 품목 등록 (업체, 레거시)
//   POST   /api/v1/products/organizer           → 품목 등록 (주관사, 1뎁스)
//   POST   /api/v1/products/:id/claim           → 품목 선점 (업체)
//   POST   /api/v1/products/:id/assign-vendor   → 업체 배정 (주관사)
//   POST   /api/v1/products/:id/unclaim         → 업체 참가 취소 (주관사)
//   PUT    /api/v1/products/:id                 → 품목 수정
//   GET    /api/v1/products/vendor/mine         → 내 품목 (업체)
//
// API 목록 — ProductItem (2뎁스):
//   GET    /api/v1/products/:productId/items          → 상세 품목 목록
//   POST   /api/v1/products/:productId/items          → 상세 품목 등록 (업체)
//   GET    /api/v1/product-items/:id                   → 상세 품목 단건
//   PUT    /api/v1/product-items/:id                   → 상세 품목 수정
//   DELETE /api/v1/product-items/:id                   → 상세 품목 삭제
// ============================================

import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ProductsService } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { CreateProductOrganizerDto } from './dto/create-product-organizer.dto';
import { CreateProductItemDto } from './dto/create-product-item.dto';
import { JwtAuthGuard, RolesGuard, Roles } from '../auth/roles.guard';

@Controller()
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Product (1뎁스) API
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // 전체 품목 목록 (주관사/관리자용, 2뎁스 포함)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Get('products')
  async findAll(
    @Query('eventId') eventId?: string,
    @Query('category') category?: string,
  ) {
    return this.productsService.findAll(eventId, category);
  }

  // 행사별 품목 목록 (2뎁스 포함)
  // 업체(VENDOR)가 조회하면 다른 업체의 참가비/수수료/가격 숨김
  @UseGuards(JwtAuthGuard)
  @Get('events/:eventId/products')
  async findByEvent(
    @Request() req: any,
    @Param('eventId') eventId: string,
    @Query('housingType') housingType?: string,
  ) {
    const vendorId = req.user.role === 'VENDOR' ? req.user.id : undefined;
    return this.productsService.findByEvent(eventId, housingType, vendorId);
  }

  // 가용 품목 목록 (업체 미배정)
  @UseGuards(JwtAuthGuard)
  @Get('events/:eventId/products/available')
  async findAvailable(@Param('eventId') eventId: string) {
    return this.productsService.findAvailable(eventId);
  }

  // 내가 배정된 품목 목록 (업체용, 2뎁스 포함)
  // ※ 반드시 GET products/:id 보다 위에 위치해야 라우트 충돌 방지
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Get('products/vendor/mine')
  async findMyProducts(
    @Request() req: any,
    @Query('eventId') eventId?: string,
  ) {
    return this.productsService.findByVendor(req.user.id, eventId);
  }

  // 품목 상세 조회 (2뎁스 포함)
  @UseGuards(JwtAuthGuard)
  @Get('products/:id')
  async findOne(@Param('id') id: string) {
    return this.productsService.findOne(id);
  }

  // 품목 등록 (주관사용 — 1뎁스)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Post('products/organizer')
  async createByOrganizer(
    @Request() req: any,
    @Body() dto: CreateProductOrganizerDto,
  ) {
    return this.productsService.createByOrganizer(req.user.id, dto);
  }

  // 품목 등록 (업체, 레거시 호환)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR', 'ORGANIZER', 'ADMIN')
  @Post('products')
  async create(@Request() req: any, @Body() dto: CreateProductDto) {
    return this.productsService.create(req.user.id, dto);
  }

  // 품목 선점 (업체)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Post('products/:id/claim')
  async claimProduct(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: { vendorName: string },
  ) {
    return this.productsService.claimProduct(id, req.user.id, body.vendorName);
  }

  // 업체 배정 (주관사가 드롭다운으로 선택)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Post('products/:id/assign-vendor')
  async assignVendor(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: { vendorId: string },
  ) {
    return this.productsService.assignVendor(id, body.vendorId, req.user.id);
  }

  // 업체 참가 취소
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Post('products/:id/unclaim')
  async unclaimProduct(
    @Request() req: any,
    @Param('id') id: string,
  ) {
    return this.productsService.unclaimProduct(id, req.user.id);
  }

  // 품목 순서 변경 (주관사용)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Patch('events/:eventId/products/reorder')
  async reorderProducts(
    @Param('eventId') eventId: string,
    @Body() body: { productIds: string[] },
  ) {
    return this.productsService.reorderProducts(eventId, body.productIds);
  }

  // 품목 수정
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR', 'ORGANIZER', 'ADMIN')
  @Put('products/:id')
  async update(
    @Param('id') id: string,
    @Body() dto: Partial<CreateProductDto>,
  ) {
    return this.productsService.update(id, dto);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ProductItem (2뎁스) API
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // 상세 품목 목록 (특정 1뎁스 하위)
  @UseGuards(JwtAuthGuard)
  @Get('products/:productId/items')
  async findItemsByProduct(@Param('productId') productId: string) {
    return this.productsService.findItemsByProduct(productId);
  }

  // 상세 품목 등록 (업체가 2뎁스 패키지 추가)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Post('products/:productId/items')
  async createItem(
    @Request() req: any,
    @Param('productId') productId: string,
    @Body() dto: CreateProductItemDto,
  ) {
    return this.productsService.createItem(productId, req.user.id, dto);
  }

  // 상세 품목 단건 조회
  @UseGuards(JwtAuthGuard)
  @Get('product-items/:id')
  async findOneItem(@Param('id') id: string) {
    return this.productsService.findOneItem(id);
  }

  // 상세 품목 수정
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR', 'ORGANIZER', 'ADMIN')
  @Put('product-items/:id')
  async updateItem(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: Partial<CreateProductItemDto>,
  ) {
    return this.productsService.updateItem(id, req.user.id, dto);
  }

  // 상세 품목 삭제
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR', 'ORGANIZER', 'ADMIN')
  @Delete('product-items/:id')
  async deleteItem(
    @Request() req: any,
    @Param('id') id: string,
  ) {
    return this.productsService.deleteItem(id, req.user.id);
  }
}
