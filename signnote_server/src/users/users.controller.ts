// ============================================
// 사용자 컨트롤러 (Users Controller)
//
// API 목록:
//   GET /api/v1/users          → 전체 사용자 목록 (주관사/관리자)
//   GET /api/v1/users/:id      → 사용자 상세 (주관사/관리자)
// ============================================

import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard, RolesGuard, Roles } from '../auth/roles.guard';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // 전체 사용자 목록 (주관사/관리자만)
  // ?role=CUSTOMER 로 역할별 필터 가능
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Get()
  async findAll(@Query('role') role?: string) {
    return this.usersService.findAll(role);
  }

  // 사용자 상세 (주관사/관리자만)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Get(':id')
  async findOne(@Param('id') id: string) {
    const user = await this.usersService.findById(id);
    if (!user) return null;
    // 비밀번호 제외하고 반환
    const { password: _, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }
}
