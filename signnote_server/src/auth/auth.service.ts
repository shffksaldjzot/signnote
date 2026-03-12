// ============================================
// 인증 서비스 (Auth Service)
// 로그인, 회원가입, 토큰 발급/검증, 행사 입장 로직
//
// 쉽게 말하면:
//   - 회원가입: 새 사용자 등록
//   - 로그인: 아이디/비밀번호 확인 → 통행증(토큰) 발급
//   - 토큰 갱신: 만료된 통행증 새로 발급
//   - 행사 입장: 참여 코드로 행사 찾기
// ============================================

import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { UsersService } from '../users/users.service';
import { PrismaService } from '../common/prisma.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import { EnterEventDto } from './dto/enter-event.dto';
import { ActivityLogsService } from '../activity-logs/activity-logs.service';
import { NotificationsService, NotificationType } from '../notifications/notifications.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly prisma: PrismaService,
    private readonly activityLogs: ActivityLogsService,
    private readonly notifications: NotificationsService,
  ) {}

  // ---- 회원가입 ----
  async register(dto: CreateUserDto) {
    // 사용자 생성 (비밀번호 암호화는 UsersService에서 처리)
    const user = await this.usersService.create(dto);

    // 업체/주관사는 승인 대기 → 토큰은 발급하되 isApproved 상태 알려주기
    const tokens = await this.generateTokens(user.id, user.role);

    // 회원가입 로그 기록
    await this.activityLogs.log({
      userId: user.id,
      action: 'REGISTER',
      detail: `${user.name} (${user.role}) 회원가입`,
    });

    return {
      user,
      ...tokens,
    };
  }

  // ---- 로그인 ----
  async login(dto: LoginDto) {
    // 이메일로 사용자 찾기
    const user = await this.usersService.findByEmail(dto.email);
    if (!user) {
      throw new UnauthorizedException('이메일 또는 비밀번호가 올바르지 않습니다');
    }

    // 비밀번호 확인 (암호화된 비밀번호와 비교)
    const isPasswordValid = await bcrypt.compare(dto.password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('이메일 또는 비밀번호가 올바르지 않습니다');
    }

    // 승인 체크: 업체/주관사는 관리자 승인이 필요
    if (!user.isApproved) {
      throw new ForbiddenException('관리자 승인 대기 중입니다. 승인 후 로그인할 수 있습니다.');
    }

    // 토큰 발급
    const tokens = await this.generateTokens(user.id, user.role);

    // 로그인 로그 기록
    await this.activityLogs.log({
      userId: user.id,
      action: 'LOGIN',
      detail: `${user.name} (${user.role}) 로그인`,
    });

    // 비밀번호 빼고 반환
    const { password: _, ...userWithoutPassword } = user;
    return {
      user: userWithoutPassword,
      ...tokens,
    };
  }

  // ---- 토큰 갱신 ----
  // 통행증(Access Token)이 만료되면, 갱신 토큰(Refresh Token)으로 새로 발급
  async refreshToken(refreshToken: string) {
    try {
      // 갱신 토큰 검증
      const payload = this.jwtService.verify(refreshToken);

      // 사용자가 아직 존재하는지 확인
      const user = await this.usersService.findById(payload.sub);
      if (!user) {
        throw new UnauthorizedException('사용자를 찾을 수 없습니다');
      }

      // 새 토큰 발급
      return this.generateTokens(user.id, user.role);
    } catch {
      throw new UnauthorizedException('유효하지 않은 갱신 토큰입니다');
    }
  }

  // ---- 행사 입장 (참여 코드) ----
  // 역할에 따라 올바른 코드 유형만 허용
  // - CUSTOMER → entryCode(고객코드)로만 검색
  // - VENDOR → vendorEntryCode(업체코드)로만 검색
  // - 비로그인 → 둘 다 검색 (호환성)
  async enterEvent(dto: EnterEventDto, userId?: string) {
    // 로그인한 사용자의 역할 확인
    let userRole: string | null = null;
    if (userId) {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { role: true },
      });
      userRole = user?.role ?? null;
    }

    let event = null;

    if (userRole === 'VENDOR') {
      // 업체는 업체코드(vendorEntryCode)로만 입장 가능
      event = await this.prisma.event.findFirst({
        where: { vendorEntryCode: dto.entryCode },
      });
      if (!event) {
        throw new NotFoundException('유효하지 않은 업체 참여 코드입니다. 업체 전용 코드를 입력해 주세요.');
      }
    } else if (userRole === 'CUSTOMER') {
      // 고객은 고객코드(entryCode)로만 입장 가능
      event = await this.prisma.event.findUnique({
        where: { entryCode: dto.entryCode },
      });
      if (!event) {
        throw new NotFoundException('유효하지 않은 고객 참여 코드입니다. 고객 전용 코드를 입력해 주세요.');
      }
    } else {
      // 비로그인 또는 관리자/주관사 → 둘 다 검색
      event = await this.prisma.event.findUnique({
        where: { entryCode: dto.entryCode },
      });
      if (!event) {
        event = await this.prisma.event.findFirst({
          where: { vendorEntryCode: dto.entryCode },
        });
      }
      if (!event) {
        throw new NotFoundException('유효하지 않은 참여 코드입니다');
      }
    }

    // 로그인한 사용자가 있으면 중복 참가 체크 + 참여 기록 저장
    if (userId) {
      // 이미 참여한 행사인지 확인
      const existing = await this.prisma.eventParticipant.findUnique({
        where: {
          eventId_userId: {
            eventId: event.id,
            userId: userId,
          },
        },
      });

      if (existing) {
        throw new ForbiddenException('이미 참여한 행사입니다');
      }

      // 참여 기록 저장
      try {
        await this.prisma.eventParticipant.create({
          data: {
            eventId: event.id,
            userId: userId,
          },
        });
      } catch (e) {
        // 참여 기록 저장 실패해도 행사 입장은 진행
        console.error('EventParticipant 저장 실패:', e.message);
      }
    }

    // 행사 입장 로그 기록
    if (userId) {
      await this.activityLogs.log({
        userId,
        action: 'EVENT_ENTER',
        target: event.id,
        detail: `행사 입장: ${event.title} (코드: ${dto.entryCode})`,
      });

      // 협력업체가 행사에 참여하면 주관사에게 알림 전송
      if (userRole === 'VENDOR' && event.organizerId) {
        const vendor = await this.prisma.user.findUnique({
          where: { id: userId },
          select: { name: true },
        });
        const vendorName = vendor?.name ?? '업체';
        await this.notifications.send({
          userId: event.organizerId,
          type: NotificationType.VENDOR_JOINED,
          title: '새 업체가 행사에 참여했습니다',
          body: `${vendorName}이(가) '${event.title}' 행사에 참여했습니다.`,
          data: { eventId: event.id, vendorId: userId },
        });
      }
    }

    return {
      eventId: event.id,
      title: event.title,
      status: event.status,
      housingTypes: event.housingTypes,
      startDate: event.startDate,
      endDate: event.endDate,
    };
  }

  // ---- 비밀번호 확인 (중요 작업 전 본인 인증) ----
  async verifyPassword(userId: string, password: string) {
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      throw new UnauthorizedException('비밀번호가 올바르지 않습니다');
    }

    return { verified: true };
  }

  // ---- 토큰 생성 (내부용) ----
  // Access Token: 짧은 유효기간 (1시간) - 매 요청에 사용
  // Refresh Token: 긴 유효기간 (7일) - Access Token 갱신용
  private async generateTokens(userId: string, role: string) {
    const payload = { sub: userId, role };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, { expiresIn: '1h' }),
      this.jwtService.signAsync(payload, { expiresIn: '7d' }),
    ]);

    return {
      accessToken,
      refreshToken,
    };
  }
}
