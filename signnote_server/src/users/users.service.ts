// ============================================
// 사용자 서비스 (Users Service)
// 사용자 데이터를 DB에서 조회/생성/승인하는 로직
// ============================================

import { Injectable, ConflictException, NotFoundException, BadRequestException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../common/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  // 이메일로 사용자 찾기 (로그인 시 사용)
  async findByEmail(email: string) {
    return this.prisma.user.findUnique({
      where: { email },
    });
  }

  // ID로 사용자 찾기
  async findById(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
    });
  }

  // 전체 사용자 목록 조회 (주관사/관리자용)
  // role 필터: 'CUSTOMER', 'VENDOR', 'ORGANIZER' 등
  async findAll(role?: string) {
    const where: any = {};
    if (role) where.role = role;

    // 고객 조회 시 행사 참여 정보(동/호수/타입/참여일/행사명) 포함
    const isCustomerQuery = role === 'CUSTOMER';

    // select 객체를 명시적으로 구성 (spread 문법 대신 조건 분기)
    const baseSelect: any = {
      id: true,
      email: true,
      name: true,
      phone: true,
      role: true,
      representativeName: true,     // 대표자 성명
      businessNumber: true,
      businessAddress: true,        // 사업장 주소
      businessLicenseImage: true,   // 사업자등록증 이미지
      isApproved: true,             // 승인 여부
      createdAt: true,
    };

    // 고객 조회일 때만 참여 정보 포함
    if (isCustomerQuery) {
      baseSelect.eventParticipants = {
        select: {
          dong: true,
          ho: true,
          housingType: true,
          joinedAt: true,
          event: { select: { id: true, title: true } },
        },
        orderBy: { joinedAt: 'desc' as const },
      };
    }

    const users = await this.prisma.user.findMany({
      where,
      select: baseSelect,
      orderBy: { createdAt: 'desc' },
    });

    // 고객인 경우 참여 정보를 플랫하게 펼침 (최신 참여 기준)
    if (isCustomerQuery) {
      return users.map((u: any) => {
        const participant = u.eventParticipants?.[0]; // 최신 참여 정보
        return {
          ...u,
          dong: participant?.dong ?? null,
          ho: participant?.ho ?? null,
          housingType: participant?.housingType ?? null,
          joinedAt: participant?.joinedAt ?? null,
          eventTitle: participant?.event?.title ?? null,
          eventId: participant?.event?.id ?? null,
          // 여러 행사 참여 시 모든 행사 정보
          events: u.eventParticipants?.map((ep: any) => ({
            eventId: ep.event?.id,
            eventTitle: ep.event?.title,
            dong: ep.dong,
            ho: ep.ho,
            housingType: ep.housingType,
            joinedAt: ep.joinedAt,
          })) ?? [],
          eventParticipants: undefined, // 원본 제거 (불필요한 중첩 방지)
        };
      });
    }

    return users;
  }

  // 주관사의 행사에 참여한 업체(VENDOR)만 조회
  // EventParticipant 테이블에서 주관사의 행사에 입장한 VENDOR를 찾음
  async findVendorsByOrganizer(organizerId: string) {
    // 1. 주관사가 만든 행사 ID 목록 가져오기
    const events = await this.prisma.event.findMany({
      where: { organizerId },
      select: { id: true },
    });
    const eventIds = events.map(e => e.id);

    if (eventIds.length === 0) return [];

    // 2. 해당 행사에 참여한 VENDOR 사용자 조회 (중복 제거)
    const participants = await this.prisma.eventParticipant.findMany({
      where: {
        eventId: { in: eventIds },
        user: { role: 'VENDOR' },
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true,
            phone: true,
            role: true,
            representativeName: true,
            businessNumber: true,
            businessAddress: true,
            businessLicenseImage: true,
            isApproved: true,
            createdAt: true,
          },
        },
      },
    });

    // 중복 사용자 제거 (여러 행사에 참여한 경우)
    const uniqueUsers = new Map();
    for (const p of participants) {
      uniqueUsers.set(p.user.id, p.user);
    }

    return Array.from(uniqueUsers.values());
  }

  // 새 사용자 생성 (회원가입)
  async create(dto: CreateUserDto) {
    // 이미 같은 이메일이 있는지 확인
    const existing = await this.findByEmail(dto.email);
    if (existing) {
      throw new ConflictException('이미 사용 중인 이메일입니다');
    }

    // 같은 전화번호가 있는지 확인
    if (dto.phone) {
      const existingPhone = await this.prisma.user.findFirst({
        where: { phone: dto.phone },
      });
      if (existingPhone) {
        throw new ConflictException('이미 사용 중인 전화번호입니다');
      }
    }

    // 비밀번호 암호화 (원래 비밀번호를 알 수 없게 변환)
    const hashedPassword = await bcrypt.hash(dto.password, 10);

    // 업체/주관사는 관리자 승인 필요 → isApproved = false
    // 고객은 바로 사용 가능 → isApproved = true
    const needsApproval = dto.role === 'VENDOR' || dto.role === 'ORGANIZER';

    // DB에 사용자 저장
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        password: hashedPassword,
        name: dto.name,
        phone: dto.phone,
        role: dto.role,
        representativeName: dto.representativeName,
        businessNumber: dto.businessNumber,
        businessAddress: dto.businessAddress,
        businessLicenseImage: dto.businessLicenseImage,
        bankAccount: dto.bankAccount,
        isApproved: !needsApproval,  // 업체/주관사는 false, 고객은 true
      },
    });

    // 비밀번호는 빼고 반환 (보안)
    const { password: _, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  // ---- 내 프로필 조회 (본인 전체 정보) ----
  async getMyProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        role: true,
        representativeName: true,
        businessNumber: true,
        businessAddress: true,
        businessLicenseImage: true,
        bankAccount: true,
        createdAt: true,
        // 고객인 경우 참여 행사의 동/호수/타입도 조회
        participatedEvents: {
          select: {
            dong: true,
            ho: true,
            housingType: true,
            eventId: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }

    return user;
  }

  // ---- 내 프로필 수정 (본인 정보 변경) ----
  async updateProfile(userId: string, data: {
    name?: string;
    phone?: string;
    representativeName?: string;
    businessNumber?: string;
    businessAddress?: string;
    // 비밀번호 변경 (선택)
    currentPassword?: string;
    newPassword?: string;
  }) {
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }

    // 비밀번호 변경 요청이 있으면 현재 비밀번호 확인
    if (data.newPassword) {
      if (!data.currentPassword) {
        throw new BadRequestException('현재 비밀번호를 입력해 주세요');
      }
      const isValid = await bcrypt.compare(data.currentPassword, user.password);
      if (!isValid) {
        throw new BadRequestException('현재 비밀번호가 올바르지 않습니다');
      }
      if (data.newPassword.length < 6) {
        throw new BadRequestException('새 비밀번호는 6자 이상이어야 합니다');
      }
    }

    // 업데이트할 데이터 구성
    const updateData: any = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.phone !== undefined) updateData.phone = data.phone;
    if (data.representativeName !== undefined) updateData.representativeName = data.representativeName;
    if (data.businessNumber !== undefined) updateData.businessNumber = data.businessNumber;
    if (data.businessAddress !== undefined) updateData.businessAddress = data.businessAddress;
    if (data.newPassword) {
      updateData.password = await bcrypt.hash(data.newPassword, 10);
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: updateData,
    });

    const { password: _, ...userWithoutPassword } = updated;
    return userWithoutPassword;
  }

  // ---- 일괄 회원 탈퇴 (관리자 전용) ----
  // 여러 사용자를 한 번에 삭제
  async batchDeleteUsers(userIds: string[]) {
    const results: { id: string; success: boolean; error?: string }[] = [];

    for (const userId of userIds) {
      try {
        await this.deleteUser(userId);
        results.push({ id: userId, success: true });
      } catch (e) {
        results.push({ id: userId, success: false, error: e.message });
      }
    }

    const successCount = results.filter(r => r.success).length;
    return {
      message: `${successCount}명이 탈퇴 처리되었습니다`,
      results,
    };
  }

  // ---- 사용자 승인 (관리자 전용) ----
  // 업체/주관사가 가입 신청하면, 관리자가 승인해야 로그인 가능
  // ---- 일괄 승인 (관리자 전용) ----
  async batchApproveUsers(userIds: string[]) {
    const results: { id: string; success: boolean; error?: string }[] = [];

    for (const userId of userIds) {
      try {
        await this.approveUser(userId);
        results.push({ id: userId, success: true });
      } catch (e) {
        results.push({ id: userId, success: false, error: e.message });
      }
    }

    const successCount = results.filter(r => r.success).length;
    return {
      message: `${successCount}명이 승인되었습니다`,
      results,
    };
  }

  async approveUser(userId: string) {
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { isApproved: true },
    });

    const { password: _, ...userWithoutPassword } = updated;
    return userWithoutPassword;
  }

  // ---- 비밀번호 초기화 (관리자 전용) ----
  // 무작위 8자리 비밀번호를 생성하여 해당 사용자의 비밀번호를 변경
  async resetPassword(userId: string) {
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }

    // 무작위 비밀번호 생성 (영문+숫자+특수문자 8자리)
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    const special = '!@#$%';
    let newPassword = '';
    for (let i = 0; i < 7; i++) {
      newPassword += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    // 특수문자 1개 추가
    newPassword += special.charAt(Math.floor(Math.random() * special.length));

    // 비밀번호 암호화 후 DB 저장
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword },
    });

    // 초기화된 비밀번호를 반환 (관리자에게 보여주기 위해)
    return { newPassword };
  }

  // ---- 본인 비밀번호 변경 (로그인한 모든 사용자) ----
  // 현재 비밀번호 확인 후 새 비밀번호로 변경
  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }

    // 현재 비밀번호가 맞는지 확인
    const isValid = await bcrypt.compare(currentPassword, user.password);
    if (!isValid) {
      throw new BadRequestException('현재 비밀번호가 올바르지 않습니다');
    }

    // 새 비밀번호 암호화 후 저장
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword },
    });

    return { message: '비밀번호가 변경되었습니다' };
  }

  // ---- 회원 강제 탈퇴 (관리자 전용) ----
  // 승인된 사용자도 관리자가 강제 탈퇴 가능
  // 연관된 모든 데이터를 순서대로 삭제한 후 사용자 삭제
  async deleteUser(userId: string) {
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }

    // 1. 알림 삭제
    await this.prisma.notification.deleteMany({ where: { userId } });
    // 2. 장바구니 삭제 (본인이 담은 것)
    await this.prisma.cartItem.deleteMany({ where: { userId } });
    // 3. 고객으로서의 계약 관련 삭제 (결제 → 정산 → 계약 순서)
    const customerContracts = await this.prisma.contract.findMany({
      where: { customerId: userId },
      select: { id: true },
    });
    const customerContractIds = customerContracts.map(c => c.id);
    if (customerContractIds.length > 0) {
      await this.prisma.payment.deleteMany({ where: { contractId: { in: customerContractIds } } });
      await this.prisma.settlement.deleteMany({ where: { contractId: { in: customerContractIds } } });
      await this.prisma.contract.deleteMany({ where: { customerId: userId } });
    }
    // 4. 업체가 등록한 품목 처리 (품목 + 상세품목 삭제, 계약은 스냅샷으로 보존)
    const vendorProducts = await this.prisma.product.findMany({
      where: { vendorId: userId },
      select: { id: true },
    });
    const vendorProductIds = vendorProducts.map(p => p.id);
    if (vendorProductIds.length > 0) {
      // 4-1. 해당 품목의 장바구니 항목 삭제 (다른 고객이 담아둔 것)
      await this.prisma.cartItem.deleteMany({
        where: { productId: { in: vendorProductIds } },
      });
      // 4-2. 상세품목 삭제 (ProductItem은 Product에 Cascade이므로 Product 삭제 시 자동 삭제)
      // 4-3. 품목 삭제 → 계약의 productId/productItemId는 SetNull로 null 처리됨
      //       계약서에는 productName, vendorName 등 스냅샷이 남아있어 정보 보존
      await this.prisma.product.deleteMany({
        where: { vendorId: userId },
      });
    }
    // 5. 행사 참여 기록 삭제
    await this.prisma.eventParticipant.deleteMany({ where: { userId } });
    // 6. 주관사가 만든 행사가 있으면 관련 데이터 정리
    const organizedEvents = await this.prisma.event.findMany({
      where: { organizerId: userId },
      select: { id: true },
    });
    if (organizedEvents.length > 0) {
      const eventIds = organizedEvents.map(e => e.id);
      await this.prisma.eventParticipant.deleteMany({ where: { eventId: { in: eventIds } } });
      await this.prisma.cartItem.deleteMany({ where: { eventId: { in: eventIds } } });
      // 행사의 계약/결제/정산 삭제
      const eventContracts = await this.prisma.contract.findMany({
        where: { eventId: { in: eventIds } },
        select: { id: true },
      });
      const eventContractIds = eventContracts.map(c => c.id);
      if (eventContractIds.length > 0) {
        await this.prisma.payment.deleteMany({ where: { contractId: { in: eventContractIds } } });
        await this.prisma.settlement.deleteMany({ where: { contractId: { in: eventContractIds } } });
        await this.prisma.contract.deleteMany({ where: { eventId: { in: eventIds } } });
      }
      await this.prisma.product.deleteMany({ where: { eventId: { in: eventIds } } });
      await this.prisma.event.deleteMany({ where: { organizerId: userId } });
    }
    // 7. 사용자 삭제
    await this.prisma.user.delete({ where: { id: userId } });

    return { message: `${user.name}이(가) 탈퇴 처리되었습니다` };
  }

  // ---- 사용자 가입 거부 (관리자 전용) ----
  // 승인 거부 시 해당 계정 삭제
  async rejectUser(userId: string) {
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }

    await this.prisma.user.delete({
      where: { id: userId },
    });

    return { message: '사용자가 삭제되었습니다' };
  }
}
