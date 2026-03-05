// ============================================
// 상품 컨트롤러 (Products Controller)
//
// API 목록:
//   GET    /api/v1/events/:eventId/products          → 행사별 상품 목록
//   GET    /api/v1/events/:eventId/products/available → 가용 품목 목록 (업체용)
//   GET    /api/v1/products/:id                      → 상품 상세
//   POST   /api/v1/products                          → 상품 등록 (업체)
//   POST   /api/v1/products/organizer                → 품목 등록 (주관사)
//   POST   /api/v1/products/:id/claim                → 품목 선점 (업체)
//   PUT    /api/v1/products/:id                      → 상품 수정
//   GET    /api/v1/products/vendor/mine              → 내가 등록한 상품 목록 (업체)
// ============================================

import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ProductsService } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { CreateProductOrganizerDto } from './dto/create-product-organizer.dto';
import { JwtAuthGuard, RolesGuard, Roles } from '../auth/roles.guard';

@Controller()
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  // 전체 상품 목록 (주관사/관리자용)
  // ?eventId=xxx&category=xxx 로 필터 가능
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Get('products')
  async findAll(
    @Query('eventId') eventId?: string,
    @Query('category') category?: string,
  ) {
    return this.productsService.findAll(eventId, category);
  }

  // 행사별 상품 목록 (로그인 필요)
  // ?housingType=84A 로 평형 필터 가능
  @UseGuards(JwtAuthGuard)
  @Get('events/:eventId/products')
  async findByEvent(
    @Param('eventId') eventId: string,
    @Query('housingType') housingType?: string,
  ) {
    return this.productsService.findByEvent(eventId, housingType);
  }

  // 가용 품목 목록 (업체 선점 전 빈 품목들)
  @UseGuards(JwtAuthGuard)
  @Get('events/:eventId/products/available')
  async findAvailable(@Param('eventId') eventId: string) {
    return this.productsService.findAvailable(eventId);
  }

  // 상품 상세 조회
  @UseGuards(JwtAuthGuard)
  @Get('products/:id')
  async findOne(@Param('id') id: string) {
    return this.productsService.findOne(id);
  }

  // 품목 등록 (주관사용 — vendorId 없이 품목만 등록)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Post('products/organizer')
  async createByOrganizer(
    @Request() req: any,
    @Body() dto: CreateProductOrganizerDto,
  ) {
    return this.productsService.createByOrganizer(req.user.id, dto);
  }

  // 상품 등록 (업체)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR', 'ORGANIZER', 'ADMIN')
  @Post('products')
  async create(@Request() req: any, @Body() dto: CreateProductDto) {
    return this.productsService.create(req.user.id, dto);
  }

  // 품목 선점 (업체가 품목 선택)
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

  // 업체 참가 취소 (주관사/관리자가 품목에서 업체 해제)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Post('products/:id/unclaim')
  async unclaimProduct(
    @Request() req: any,
    @Param('id') id: string,
  ) {
    return this.productsService.unclaimProduct(id, req.user.id);
  }

  // 상품 수정 (업체/주관사만)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR', 'ORGANIZER', 'ADMIN')
  @Put('products/:id')
  async update(
    @Param('id') id: string,
    @Body() dto: Partial<CreateProductDto>,
  ) {
    return this.productsService.update(id, dto);
  }

  // 내가 등록한 상품 목록 (업체용)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Get('products/vendor/mine')
  async findMyProducts(
    @Request() req: any,
    @Query('eventId') eventId?: string,
  ) {
    return this.productsService.findByVendor(req.user.id, eventId);
  }
}
