// ============================================
// Signnote 서버의 본부 (루트 모듈)
// 모든 기능 모듈을 여기서 등록합니다
// (회사 본사에 각 부서를 등록하는 것과 같아요)
// ============================================

import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './common/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { EventsModule } from './events/events.module';
import { ProductsModule } from './products/products.module';
import { CartsModule } from './carts/carts.module';
import { ContractsModule } from './contracts/contracts.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [
    // 환경 변수 설정 (.env 파일 로딩)
    ConfigModule.forRoot({
      isGlobal: true,   // 전역 사용 가능
    }),
    // 데이터베이스 연결 (Prisma)
    PrismaModule,
    // 인증 모듈 (Phase 2) ✅
    AuthModule,
    // 사용자 모듈 ✅
    UsersModule,
    // 행사 모듈 (Phase 3) ✅
    EventsModule,
    // 상품 모듈 (Phase 3) ✅
    ProductsModule,
    // 장바구니 모듈 (Phase 4) ✅
    CartsModule,
    // 계약 모듈 (Phase 4) ✅
    ContractsModule,
    // PaymentsModule,     // 결제 (Phase 5)
    // SettlementsModule,  // 정산 (Phase 7)
    // TaxInvoicesModule,  // 세금계산서 (Phase 8)
    // NotificationsModule,// 알림 (Phase 10)
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
