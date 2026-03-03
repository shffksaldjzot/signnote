// ============================================
// 역할 기반 접근 제어 (RBAC Guard)
//
// "이 API는 업체만 쓸 수 있어", "이건 주관사만 가능해" 같은 규칙을 적용
//
// 사용 예시:
//   @Roles('VENDOR')              → 업체만 접근 가능
//   @Roles('ORGANIZER', 'ADMIN')  → 주관사 또는 관리자만 접근 가능
//   @UseGuards(JwtAuthGuard, RolesGuard)  → 로그인 + 역할 확인
// ============================================

import {
  Injectable,
  CanActivate,
  ExecutionContext,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';

// 역할 지정 데코레이터 (컨트롤러 메서드에 붙여서 사용)
export const ROLES_KEY = 'roles';
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);

// JWT 인증 가드 (로그인했는지 확인)
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}

// 역할 확인 가드 (특정 역할만 허용)
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    // 이 API에 필요한 역할 목록 가져오기
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    // 역할 지정이 없으면 누구나 접근 가능
    if (!requiredRoles) {
      return true;
    }

    // 현재 로그인한 사용자의 역할 확인
    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.includes(user.role);
  }
}
