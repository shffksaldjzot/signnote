// ============================================
// 행사 컨트롤러 (Events Controller)
//
// API 목록:
//   GET    /api/v1/events       → 행사 목록
//   GET    /api/v1/events/:id   → 행사 상세
//   POST   /api/v1/events       → 행사 생성 (주관사만)
//   PUT    /api/v1/events/:id   → 행사 수정 (주관사만)
// ============================================

import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { EventsService } from './events.service';
import { CreateEventDto } from './dto/create-event.dto';
import { JwtAuthGuard, RolesGuard, Roles } from '../auth/roles.guard';

@Controller('events')
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  // 행사 목록 조회 (로그인 필요, 역할별 필터링)
  @UseGuards(JwtAuthGuard)
  @Get()
  async findAll(@Request() req: any) {
    return this.eventsService.findAll(req.user.id, req.user.role);
  }

  // 행사 생성 (주관사만 가능)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Post()
  async create(@Request() req: any, @Body() dto: CreateEventDto) {
    return this.eventsService.create(req.user.id, dto);
  }

  // ※ 라우트 순서 중요: 구체적 경로가 :id 보다 먼저 위치해야 함

  // 행사 참여자 목록 조회 (주관사가 업체 드롭다운에 사용)
  // ?role=VENDOR → 업체만 필터
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Get(':id/participants')
  async getParticipants(
    @Param('id') id: string,
    @Query('role') role?: string,
  ) {
    return this.eventsService.getParticipants(id, role);
  }

  // 내 참여 정보 조회 (고객이 자기 동/호수/타입 확인)
  @UseGuards(JwtAuthGuard)
  @Get(':id/my-info')
  async getMyParticipantInfo(
    @Param('id') id: string,
    @Request() req: any,
  ) {
    return this.eventsService.getParticipantInfo(id, req.user.id);
  }

  // 행사 상세 조회 (로그인 필요) — :id 라우트는 구체적 경로 뒤에 배치
  @UseGuards(JwtAuthGuard)
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.eventsService.findOne(id);
  }

  // 고객 평형 정보 저장 (동/호수/타입)
  @UseGuards(JwtAuthGuard)
  @Put(':id/participant-info')
  async updateParticipantInfo(
    @Param('id') id: string,
    @Request() req: any,
    @Body() body: { dong?: string; ho?: string; housingType?: string },
  ) {
    return this.eventsService.updateParticipantInfo(id, req.user.id, body);
  }

  // 행사 수정 (주관사만 가능) — :id 라우트는 구체적 경로 뒤에 배치
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Put(':id')
  async update(@Param('id') id: string, @Body() dto: Partial<CreateEventDto>) {
    return this.eventsService.update(id, dto);
  }

  // 행사 참가 취소 (업체/고객이 자기 참여 기록 삭제)
  @UseGuards(JwtAuthGuard)
  @Delete(':id/leave')
  async leave(@Param('id') id: string, @Request() req: any) {
    return this.eventsService.leaveEvent(id, req.user.id);
  }

  // 행사 삭제 (주관사/관리자만 가능) — :id 라우트는 구체적 경로 뒤에 배치
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Delete(':id')
  async remove(@Param('id') id: string, @Request() req: any) {
    return this.eventsService.remove(id, req.user.id);
  }
}
