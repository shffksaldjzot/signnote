// ============================================
// 행사 서비스 (Events Service)
// 행사 데이터를 DB에서 조회/생성/수정하는 로직
// ============================================

import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/prisma.service';
import { CreateEventDto } from './dto/create-event.dto';
import { ActivityLogsService } from '../activity-logs/activity-logs.service';

@Injectable()
export class EventsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly activityLogs: ActivityLogsService,
  ) {}

  // 행사 목록 조회 (역할별 필터링)
  // - ADMIN: 전체 행사 조회 (삭제된 행사 포함)
  // - ORGANIZER: 본인이 만든 행사만 (삭제 제외)
  // - VENDOR/CUSTOMER: 참여한 행사만 (삭제 제외)
  async findAll(userId: string, role: string) {
    let where: any = {};

    if (role === 'ORGANIZER') {
      // 주관사는 본인이 만든 행사만 조회 (삭제 제외)
      where = { organizerId: userId, deletedAt: null };
    } else if (role === 'VENDOR' || role === 'CUSTOMER') {
      // 업체/고객은 참여한 행사만 조회 (삭제 제외)
      where = {
        deletedAt: null,
        participants: {
          some: { userId },
        },
      };
    }
    // ADMIN은 전체 조회 (삭제된 행사 포함하여 관리)

    return this.prisma.event.findMany({
      where,
      include: {
        organizer: {
          select: { id: true, name: true },  // 주관사명 포함
        },
      },
      orderBy: { startDate: 'desc' },  // 최신순 정렬
    });
  }

  // 행사 상세 조회 (상품 목록 포함)
  async findOne(id: string) {
    const event = await this.prisma.event.findUnique({
      where: { id },
      include: {
        products: true,    // 이 행사의 상품 목록도 함께 조회
        organizer: {
          select: { id: true, name: true, email: true },  // 주관사 정보 (비밀번호 제외)
        },
      },
    });

    if (!event) {
      throw new NotFoundException('행사를 찾을 수 없습니다');
    }

    return event;
  }

  // 행사 생성 (주관사만 가능)
  async create(organizerId: string, dto: CreateEventDto) {
    // 고객용/업체용 참여 코드 각각 생성 (숫자 6자리, 서로 다른 값)
    const entryCode = await this.generateUniqueEntryCode();
    const vendorEntryCode = await this.generateUniqueEntryCode(entryCode);

    const event = await this.prisma.event.create({
      data: {
        title: dto.title,
        organizerId,
        contractMethod: dto.contractMethod ?? 'online',
        siteName: dto.siteName,
        unitCount: dto.unitCount ?? 0,
        moveInDate: dto.moveInDate ? new Date(dto.moveInDate) : null,
        housingTypes: dto.housingTypes,
        coverImage: dto.coverImage,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
        cancelDeadlineStart: dto.cancelDeadlineStart
          ? new Date(dto.cancelDeadlineStart) : null,
        cancelDeadlineEnd: dto.cancelDeadlineEnd
          ? new Date(dto.cancelDeadlineEnd) : null,
        allowOnlineContract: dto.allowOnlineContract ?? false,
        ...(dto.depositRate !== undefined && { depositRate: dto.depositRate }),
        entryCode,
        vendorEntryCode,
      },
    });

    // 행사 생성 로그 기록
    await this.activityLogs.log({
      userId: organizerId,
      action: 'EVENT_CREATE',
      target: event.id,
      detail: `행사 생성: ${dto.title}`,
    });

    return event;
  }

  // 행사 수정
  async update(id: string, dto: Partial<CreateEventDto>) {
    const event = await this.prisma.event.findUnique({ where: { id } });
    if (!event) {
      throw new NotFoundException('행사를 찾을 수 없습니다');
    }

    const updated = await this.prisma.event.update({
      where: { id },
      data: {
        ...(dto.title && { title: dto.title }),
        ...(dto.contractMethod && { contractMethod: dto.contractMethod }),
        ...(dto.siteName && { siteName: dto.siteName }),
        ...(dto.unitCount && { unitCount: dto.unitCount }),
        ...(dto.moveInDate && { moveInDate: new Date(dto.moveInDate) }),
        ...(dto.housingTypes && { housingTypes: dto.housingTypes }),
        ...(dto.coverImage && { coverImage: dto.coverImage }),
        ...(dto.startDate && { startDate: new Date(dto.startDate) }),
        ...(dto.endDate && { endDate: new Date(dto.endDate) }),
        ...(dto.cancelDeadlineStart && { cancelDeadlineStart: new Date(dto.cancelDeadlineStart) }),
        ...(dto.cancelDeadlineEnd && { cancelDeadlineEnd: new Date(dto.cancelDeadlineEnd) }),
        ...(dto.allowOnlineContract !== undefined && { allowOnlineContract: dto.allowOnlineContract }),
        ...(dto.depositRate !== undefined && { depositRate: dto.depositRate }),
      },
    });

    // 행사 수정 로그 기록
    await this.activityLogs.log({
      userId: event.organizerId,
      action: 'EVENT_UPDATE',
      target: id,
      detail: `행사 수정: ${updated.title}`,
    });

    return updated;
  }

  // 행사 소프트 삭제 (주관사/관리자만 가능)
  // 실제 DB에서 삭제하지 않고 deletedAt만 설정 → 관리자는 계속 볼 수 있음
  async remove(id: string, userId: string) {
    const event = await this.prisma.event.findUnique({ where: { id } });
    if (!event) {
      throw new NotFoundException('행사를 찾을 수 없습니다');
    }

    // 소프트 삭제: deletedAt 시각만 설정
    await this.prisma.event.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    // 삭제 로그 기록
    await this.activityLogs.log({
      userId,
      action: 'EVENT_DELETE',
      target: id,
      detail: `행사 삭제: ${event.title}`,
    });

    return { message: '행사가 삭제되었습니다' };
  }

  // 행사 참가 취소 (업체/고객이 자기 참여 기록 삭제)
  async leaveEvent(eventId: string, userId: string) {
    const event = await this.prisma.event.findUnique({ where: { id: eventId } });
    if (!event) {
      throw new NotFoundException('행사를 찾을 수 없습니다');
    }

    await this.prisma.eventParticipant.deleteMany({
      where: { eventId, userId },
    });

    // 참가취소 로그 기록
    await this.activityLogs.log({
      userId,
      action: 'EVENT_LEAVE',
      target: eventId,
      detail: `행사 참가 취소: ${event.title}`,
    });

    return { message: '행사 참가가 취소되었습니다' };
  }

  // 행사 참여자 목록 조회 (역할 필터 가능)
  // role: 'VENDOR' → 업체만, 'CUSTOMER' → 고객만, 없으면 전체
  async getParticipants(eventId: string, role?: string) {
    const event = await this.prisma.event.findUnique({ where: { id: eventId } });
    if (!event) {
      throw new NotFoundException('행사를 찾을 수 없습니다');
    }

    const where: any = { eventId };
    if (role) {
      where.user = { role };
    }

    const participants = await this.prisma.eventParticipant.findMany({
      where,
      include: {
        user: {
          select: { id: true, name: true, email: true, phone: true, role: true },
        },
      },
      orderBy: { joinedAt: 'asc' },
    });

    // user 정보 + 동호수/타입을 플랫하게 반환
    return participants.map((p) => ({
      id: p.user.id,
      name: p.user.name,
      email: p.user.email,
      phone: p.user.phone,
      role: p.user.role,
      dong: p.dong,
      ho: p.ho,
      housingType: p.housingType,
      joinedAt: p.joinedAt,
    }));
  }

  // 고객 평형 정보 저장 (동/호수/타입)
  async updateParticipantInfo(
    eventId: string,
    userId: string,
    data: { dong?: string; ho?: string; housingType?: string },
  ) {
    const participant = await this.prisma.eventParticipant.findUnique({
      where: { eventId_userId: { eventId, userId } },
    });

    if (!participant) {
      throw new NotFoundException('참여 기록을 찾을 수 없습니다');
    }

    return this.prisma.eventParticipant.update({
      where: { id: participant.id },
      data: {
        ...(data.dong !== undefined && { dong: data.dong }),
        ...(data.ho !== undefined && { ho: data.ho }),
        ...(data.housingType !== undefined && { housingType: data.housingType }),
      },
    });
  }

  // 내 참여 정보 조회 (고객용)
  async getParticipantInfo(eventId: string, userId: string) {
    const participant = await this.prisma.eventParticipant.findUnique({
      where: { eventId_userId: { eventId, userId } },
    });

    if (!participant) {
      return { dong: null, ho: null, housingType: null };
    }

    return {
      dong: participant.dong,
      ho: participant.ho,
      housingType: participant.housingType,
    };
  }

  // 참여 코드로 행사 찾기 (입장 시 사용)
  async findByEntryCode(entryCode: string) {
    return this.prisma.event.findUnique({
      where: { entryCode },
    });
  }

  // 중복 없는 참여 코드 생성 (숫자 6자리)
  // excludeCode: 이 값과 다른 코드 생성 (고객/업체 코드 분리용)
  private async generateUniqueEntryCode(excludeCode?: string): Promise<string> {
    let code: string;
    let exists: boolean;

    do {
      // 숫자 6자리 랜덤 생성 (000000 ~ 999999)
      code = Math.floor(Math.random() * 1000000)
        .toString()
        .padStart(6, '0');
      // 제외 코드와 같으면 다시 생성
      if (excludeCode && code === excludeCode) {
        exists = true;
        continue;
      }
      // DB에 이미 있는지 확인 (고객코드 + 업체코드 모두 체크)
      const existingEntry = await this.prisma.event.findUnique({
        where: { entryCode: code },
      });
      const existingVendor = await this.prisma.event.findFirst({
        where: { vendorEntryCode: code },
      });
      exists = !!existingEntry || !!existingVendor;
    } while (exists);

    return code;
  }
}
