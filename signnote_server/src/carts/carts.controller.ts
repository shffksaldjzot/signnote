// ============================================
// 장바구니 컨트롤러 (Carts Controller)
//
// API 목록:
//   GET    /api/v1/cart              → 내 장바구니 조회
//   POST   /api/v1/cart/items        → 장바구니에 상품 추가
//   DELETE /api/v1/cart/items/:id    → 장바구니에서 상품 제거
//   DELETE /api/v1/cart/:eventId     → 장바구니 전체 비우기
//   GET    /api/v1/cart/count        → 장바구니 상품 개수
// ============================================

import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { CartsService } from './carts.service';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { JwtAuthGuard } from '../auth/roles.guard';

@Controller('cart')
export class CartsController {
  constructor(private readonly cartsService: CartsService) {}

  // 내 장바구니 조회 (로그인 필요)
  // ?eventId=xxx 로 행사별 필터 가능
  @UseGuards(JwtAuthGuard)
  @Get()
  async getCartItems(
    @Request() req: any,
    @Query('eventId') eventId?: string,
  ) {
    return this.cartsService.getCartItems(req.user.id, eventId);
  }

  // 장바구니에 상품 추가
  @UseGuards(JwtAuthGuard)
  @Post('items')
  async addItem(@Request() req: any, @Body() dto: AddCartItemDto) {
    return this.cartsService.addItem(req.user.id, dto);
  }

  // 장바구니에서 상품 제거
  @UseGuards(JwtAuthGuard)
  @Delete('items/:id')
  async removeItem(@Request() req: any, @Param('id') id: string) {
    return this.cartsService.removeItem(req.user.id, id);
  }

  // 장바구니 전체 비우기 (행사별)
  @UseGuards(JwtAuthGuard)
  @Delete(':eventId')
  async clearCart(
    @Request() req: any,
    @Param('eventId') eventId: string,
  ) {
    return this.cartsService.clearCart(req.user.id, eventId);
  }

  // 장바구니 상품 개수 조회
  @UseGuards(JwtAuthGuard)
  @Get('count')
  async getCartCount(
    @Request() req: any,
    @Query('eventId') eventId?: string,
  ) {
    const count = await this.cartsService.getCartCount(req.user.id, eventId);
    return { count };
  }
}
