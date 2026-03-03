// ============================================
// JWT 전략 (JWT Strategy)
// 앱에서 보낸 통행증(토큰)이 유효한지 확인하는 로직
//
// 쉽게 말하면: "이 사람이 로그인한 사람이 맞는지" 검사하는 것
// ============================================

import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private readonly configService: ConfigService,
    private readonly usersService: UsersService,
  ) {
    super({
      // 요청 헤더에서 토큰 추출 (Bearer xxxxx 형식)
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      // 만료된 토큰 거부
      ignoreExpiration: false,
      // 토큰 검증에 사용할 비밀 키
      secretOrKey: configService.get<string>('JWT_SECRET') || 'signnote-dev-secret',
    });
  }

  // 토큰이 유효하면 이 함수가 실행됨
  // payload = 토큰 안에 담긴 정보 (사용자 ID, 역할)
  async validate(payload: { sub: string; role: string }) {
    const user = await this.usersService.findById(payload.sub);
    if (!user) {
      throw new UnauthorizedException('사용자를 찾을 수 없습니다');
    }

    // 요청 객체에 사용자 정보를 넣어줌
    // 이후 컨트롤러에서 request.user로 접근 가능
    return { id: user.id, email: user.email, role: user.role, name: user.name };
  }
}
