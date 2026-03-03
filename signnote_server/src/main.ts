// ============================================
// Signnote 백엔드 서버 시작점
// 서버를 실행하면 가장 먼저 이 파일이 실행됩니다
// ============================================

import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  // 서버 생성
  const app = await NestFactory.create(AppModule);

  // API 주소 앞에 /api/v1 붙이기 (예: /api/v1/events)
  app.setGlobalPrefix('api/v1');

  // 입력값 검증 (잘못된 데이터가 들어오면 자동으로 거부)
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,       // 허용된 필드만 통과
      forbidNonWhitelisted: true, // 허용되지 않은 필드가 있으면 에러
      transform: true,       // 자동 타입 변환
    }),
  );

  // CORS 허용 (앱에서 서버에 접근할 수 있도록 허용)
  app.enableCors();

  // 서버 실행 (기본 포트 3000)
  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`🚀 Signnote 서버가 포트 ${port}에서 실행 중입니다`);
}
bootstrap();
