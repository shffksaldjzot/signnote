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

    const users = await this.prisma.user.findMany({
      where,
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        role: true,
        businessNumber: true,
        businessLicenseImage: true,   // 사업자등록증 이미지
        isApproved: true,             // 승인 여부
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });

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
            businessNumber: true,
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
        businessNumber: dto.businessNumber,
        businessLicenseImage: dto.businessLicenseImage,
        bankAccount: dto.bankAccount,
        isApproved: !needsApproval,  // 업체/주관사는 false, 고객은 true
      },
    });

    // 비밀번호는 빼고 반환 (보안)
    const { password: _, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  // ---- 사용자 승인 (관리자 전용) ----
  // 업체/주관사가 가입 신청하면, 관리자가 승인해야 로그인 가능
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
