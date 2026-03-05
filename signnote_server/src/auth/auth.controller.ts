// ============================================
// 인증 컨트롤러 (Auth Controller)
// 앱에서 보내는 인증 관련 요청을 받는 창구
//
// API 목록:
//   POST /api/v1/auth/register  → 회원가입
//   POST /api/v1/auth/login     → 로그인
//   POST /api/v1/auth/refresh   → 토큰 갱신
//   POST /api/v1/auth/enter     → 참여코드 입장
// ============================================

import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
import { AuthService } from './auth.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import { EnterEventDto } from './dto/enter-event.dto';
import { JwtAuthGuard } from './roles.guard';

@Controller('auth')  // /api/v1/auth 경로
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // 회원가입
  @Post('register')
  async register(@Body() dto: CreateUserDto) {
    return this.authService.register(dto);
  }

  // 로그인
  @Post('login')
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  // 토큰 갱신
  @Post('refresh')
  async refresh(@Body('refreshToken') refreshToken: string) {
    return this.authService.refreshToken(refreshToken);
  }

  // 참여 코드로 행사 입장 (로그인 필수 — 참여 기록 저장)
  @UseGuards(JwtAuthGuard)
  @Post('enter')
  async enterEvent(@Body() dto: EnterEventDto, @Request() req: any) {
    const userId = req.user?.id;
    return this.authService.enterEvent(dto, userId);
  }

  // 비밀번호 확인 (본인 비밀번호가 맞는지 검증만 하는 API)
  // 참가취소, 행사삭제 등 중요 작업 전에 비밀번호 재확인용
  @UseGuards(JwtAuthGuard)
  @Post('verify-password')
  async verifyPassword(@Request() req: any, @Body('password') password: string) {
    return this.authService.verifyPassword(req.user.id, password);
  }
}
