// ============================================
// 사용자 컨트롤러 (Users Controller)
//
// API 목록:
//   GET    /api/v1/users          → 전체 사용자 목록 (주관사/관리자)
//   GET    /api/v1/users/:id      → 사용자 상세 (주관사/관리자)
//   PATCH  /api/v1/users/me/password  → 본인 비밀번호 변경 (모든 역할)
//   PATCH  /api/v1/users/:id/approve → 사용자 승인 (관리자 전용)
//   PATCH  /api/v1/users/:id/reject  → 사용자 거부 (관리자 전용)
//
// 접근 제어:
//   - 관리자: 주관사+협력업체 전체 열람 가능
//   - 주관사: 협력업체 정보만 열람 가능
// ============================================

import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  Request,
  ForbiddenException,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard, RolesGuard, Roles } from '../auth/roles.guard';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // 전체 사용자 목록 (주관사/관리자만)
  // 주관사는 업체(VENDOR) 목록만 볼 수 있음
  // 관리자는 전체 열람 가능
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Get()
  async findAll(@Query('role') role: string, @Request() req: any) {
    const currentUser = req.user;

    // 주관사는 자기 행사에 참여한 업체(VENDOR)만 조회 가능
    if (currentUser.role === 'ORGANIZER') {
      return this.usersService.findVendorsByOrganizer(currentUser.id);
    }

    // 관리자는 모든 역할 조회 가능
    return this.usersService.findAll(role || undefined);
  }

  // ---- 내 프로필 조회 (로그인한 사용자 본인 정보) ----
  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getMyProfile(@Request() req: any) {
    return this.usersService.getMyProfile(req.user.id);
  }

  // ---- 내 프로필 수정 (로그인한 사용자 본인 정보 변경) ----
  @UseGuards(JwtAuthGuard)
  @Patch('me')
  async updateProfile(
    @Request() req: any,
    @Body() body: {
      name?: string;
      phone?: string;
      representativeName?: string;
      businessNumber?: string;
      businessAddress?: string;
      currentPassword?: string;
      newPassword?: string;
    },
  ) {
    return this.usersService.updateProfile(req.user.id, body);
  }

  // ---- 본인 비밀번호 변경 (로그인한 모든 사용자) ----
  // 현재 비밀번호 확인 후 새 비밀번호로 변경
  @UseGuards(JwtAuthGuard)
  @Patch('me/password')
  async changePassword(
    @Request() req: any,
    @Body() body: { currentPassword: string; newPassword: string },
  ) {
    return this.usersService.changePassword(
      req.user.id,
      body.currentPassword,
      body.newPassword,
    );
  }

  // ---- 일괄 회원 탈퇴 (관리자 전용) ----
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @Post('batch-delete')
  async batchDeleteUsers(@Body() body: { userIds: string[] }) {
    return this.usersService.batchDeleteUsers(body.userIds);
  }

  // ---- 일괄 승인 (관리자 전용) ----
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @Post('batch-approve')
  async batchApproveUsers(@Body() body: { userIds: string[] }) {
    return this.usersService.batchApproveUsers(body.userIds);
  }

  // 사용자 상세 (주관사/관리자만)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Get(':id')
  async findOne(@Param('id') id: string, @Request() req: any) {
    const currentUser = req.user;
    const user = await this.usersService.findById(id);
    if (!user) return null;

    // 주관사는 VENDOR 정보만 열람 가능
    if (currentUser.role === 'ORGANIZER' && user.role !== 'VENDOR') {
      throw new ForbiddenException('업체 정보만 열람할 수 있습니다');
    }

    // 비밀번호 제외하고 반환
    const { password: _, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  // ---- 사용자 승인 (관리자 전용) ----
  // 업체/주관사가 가입 신청하면 관리자가 승인해야 로그인 가능
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @Patch(':id/approve')
  async approveUser(@Param('id') id: string) {
    return this.usersService.approveUser(id);
  }

  // ---- 사용자 거부 (관리자 전용) ----
  // 승인 거부 시 해당 계정 삭제
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @Patch(':id/reject')
  async rejectUser(@Param('id') id: string) {
    return this.usersService.rejectUser(id);
  }

  // ---- 비밀번호 초기화 (관리자 전용) ----
  // 무작위 비밀번호로 변경 후 새 비밀번호를 반환
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @Patch(':id/reset-password')
  async resetPassword(@Param('id') id: string) {
    return this.usersService.resetPassword(id);
  }

  // ---- 회원 강제 탈퇴 (관리자 전용) ----
  // 승인된 사용자도 관리자가 강제로 탈퇴시킬 수 있음
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @Delete(':id')
  async deleteUser(@Param('id') id: string) {
    return this.usersService.deleteUser(id);
  }
}
