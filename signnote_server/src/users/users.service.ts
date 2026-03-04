// ============================================
// 사용자 서비스 (Users Service)
// 사용자 데이터를 DB에서 조회/생성하는 로직
// ============================================

import { Injectable, ConflictException } from '@nestjs/common';
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
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return users;
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

    // DB에 사용자 저장
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        password: hashedPassword,
        name: dto.name,
        phone: dto.phone,
        role: dto.role,
        businessNumber: dto.businessNumber,
        bankAccount: dto.bankAccount,
      },
    });

    // 비밀번호는 빼고 반환 (보안)
    const { password: _, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }
}
