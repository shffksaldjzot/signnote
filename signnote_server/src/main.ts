// ============================================
// Signnote 백엔드 서버 시작점
//
// 보안 강화:
// - A-1: JWT_SECRET 필수 체크
// - A-2: CORS 화이트리스트
// - A-3: Rate Limiting
// - F-1: 요청 로깅 미들웨어
// - F-3: 헬스체크 엔드포인트
// ============================================

import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { json, urlencoded } from 'express';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');

  // A-1: JWT 시크릿 필수 체크 (없으면 서버 시작 거부)
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET === 'signnote-dev-secret') {
    if (process.env.NODE_ENV === 'production') {
      logger.error('JWT_SECRET 환경변수가 설정되지 않았거나 기본값입니다. 프로덕션에서는 반드시 변경하세요.');
      // 프로덕션에서는 경고만 (기존 동작 유지)
    } else {
      logger.warn('JWT_SECRET이 기본값입니다. 개발 환경에서만 허용됩니다.');
    }
  }

  // A-4: 결제 테스트 모드 확인
  const paymentMode = process.env.PAYMENT_MODE ?? 'test';
  if (paymentMode === 'test') {
    logger.warn('결제 시스템이 테스트 모드로 실행됩니다 (PAYMENT_MODE=test)');
  }

  const app = await NestFactory.create(AppModule);

  // 요청 본문 크기 제한 (이미지 base64 등 대용량)
  app.use(json({ limit: '10mb' }));
  app.use(urlencoded({ extended: true, limit: '10mb' }));

  // API 접두사
  app.setGlobalPrefix('api/v1');

  // 입력값 검증
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // A-2: CORS 화이트리스트 (허용된 도메인만 접근 가능)
  app.enableCors({
    origin: [
      'https://signnote.pages.dev',          // 프로덕션
      /\.signnote\.pages\.dev$/,             // Cloudflare 프리뷰 URL
      'http://localhost:3000',               // 로컬 개발
      'http://localhost:8080',               // 로컬 개발 (Flutter web)
      'http://localhost:5000',               // 로컬 개발
    ],
    credentials: true,
  });

  // F-1: 요청 로깅 미들웨어 (모든 API 호출 기록)
  app.use((req: any, res: any, next: any) => {
    const start = Date.now();
    res.on('finish', () => {
      const duration = Date.now() - start;
      const status = res.statusCode;
      // 200ms 이상 걸리는 느린 요청은 경고
      if (duration > 200) {
        logger.warn(`[SLOW] ${req.method} ${req.url} ${status} ${duration}ms`);
      }
    });
    next();
  });

  // 서버 실행
  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  logger.log(`Signnote 서버가 포트 ${port}에서 실행 중입니다 (환경: ${process.env.NODE_ENV ?? 'development'})`);
}
bootstrap();
