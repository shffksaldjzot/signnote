// ============================================
// 인증 모듈 (Auth Module)
// 인증 관련 서비스/컨트롤러를 묶어서 등록하는 파일
// ============================================

import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './jwt.strategy';
import { UsersModule } from '../users/users.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    // 사용자 모듈 (사용자 조회/생성 기능)
    UsersModule,
    // 알림 모듈 (업체 참여 시 주관사 알림 전송)
    NotificationsModule,
    // Passport (인증 프레임워크)
    PassportModule,
    // JWT 토큰 설정
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET') || 'signnote-dev-secret',
        signOptions: { expiresIn: '1h' },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
  exports: [AuthService],
})
export class AuthModule {}
