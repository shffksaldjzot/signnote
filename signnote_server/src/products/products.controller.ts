// ============================================
// 상품 컨트롤러 (Products Controller)
//
// API 목록:
//   GET    /api/v1/events/:eventId/products    → 행사별 상품 목록
//   GET    /api/v1/products/:id                → 상품 상세
//   POST   /api/v1/products                    → 상품 등록 (업체)
//   PUT    /api/v1/products/:id                → 상품 수정 (업체)
//   GET    /api/v1/products/vendor/mine        → 내가 등록한 상품 목록 (업체)
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
import { JwtAuthGuard, RolesGuard, Roles } from '../auth/roles.guard';

@Controller()
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

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

  // 상품 상세 조회
  @UseGuards(JwtAuthGuard)
  @Get('products/:id')
  async findOne(@Param('id') id: string) {
    return this.productsService.findOne(id);
  }

  // 상품 등록 (업체/주관사만)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR', 'ORGANIZER', 'ADMIN')
  @Post('products')
  async create(@Request() req: any, @Body() dto: CreateProductDto) {
    return this.productsService.create(req.user.id, dto);
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
