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

  // 참여 코드로 행사 입장 (로그인한 사용자면 참여 기록 저장)
  @UseGuards(JwtAuthGuard)
  @Post('enter')
  async enterEvent(@Body() dto: EnterEventDto, @Request() req: any) {
    const userId = req.user?.id;
    return this.authService.enterEvent(dto, userId);
  }
}
