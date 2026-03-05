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
  // - ADMIN: 전체 행사 조회
  // - ORGANIZER: 본인이 만든 행사만
  // - VENDOR/CUSTOMER: 참여 코드로 입장한 행사만
  async findAll(userId: string, role: string) {
    let where: any = {};

    if (role === 'ORGANIZER') {
      // 주관사는 본인이 만든 행사만 조회
      where = { organizerId: userId };
    } else if (role === 'VENDOR' || role === 'CUSTOMER') {
      // 업체/고객은 참여한 행사만 조회 (EventParticipant 테이블 기준)
      where = {
        participants: {
          some: { userId },
        },
      };
    }
    // ADMIN은 where 없음 → 전체 조회

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
    // 참여 코드 자동 생성 (숫자 6자리)
    const entryCode = await this.generateUniqueEntryCode();

    const event = await this.prisma.event.create({
      data: {
        title: dto.title,
        organizerId,
        contractMethod: dto.contractMethod ?? 'online',
        siteName: dto.siteName,
        unitCount: dto.unitCount,
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
        entryCode,
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

  // 참여 코드로 행사 찾기 (입장 시 사용)
  async findByEntryCode(entryCode: string) {
    return this.prisma.event.findUnique({
      where: { entryCode },
    });
  }

  // 중복 없는 참여 코드 생성 (숫자 6자리)
  private async generateUniqueEntryCode(): Promise<string> {
    let code: string;
    let exists: boolean;

    do {
      // 숫자 6자리 랜덤 생성 (000000 ~ 999999)
      code = Math.floor(Math.random() * 1000000)
        .toString()
        .padStart(6, '0');
      // DB에 이미 있는지 확인
      const existing = await this.prisma.event.findUnique({
        where: { entryCode: code },
      });
      exists = !!existing;
    } while (exists);

    return code;
  }
}
