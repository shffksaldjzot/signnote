// ============================================
// 장바구니 모듈 (Carts Module)
// ============================================

import { Module } from '@nestjs/common';
import { CartsController } from './carts.controller';
import { CartsService } from './carts.service';

@Module({
  controllers: [CartsController],
  providers: [CartsService],
  exports: [CartsService],  // 다른 모듈에서도 사용 가능
})
export class CartsModule {}
