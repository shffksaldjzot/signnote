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

  // 행사 상세 조회 (로그인 필요)
  @UseGuards(JwtAuthGuard)
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.eventsService.findOne(id);
  }

  // 행사 생성 (주관사만 가능)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Post()
  async create(@Request() req: any, @Body() dto: CreateEventDto) {
    return this.eventsService.create(req.user.id, dto);
  }

  // 행사 수정 (주관사만 가능)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Put(':id')
  async update(@Param('id') id: string, @Body() dto: Partial<CreateEventDto>) {
    return this.eventsService.update(id, dto);
  }

  // 행사 삭제 (주관사/관리자만 가능)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Delete(':id')
  async remove(@Param('id') id: string, @Request() req: any) {
    return this.eventsService.remove(id, req.user.id);
  }

  // 행사 참가 취소 (업체/고객이 자기 참여 기록 삭제)
  @UseGuards(JwtAuthGuard)
  @Delete(':id/leave')
  async leave(@Param('id') id: string, @Request() req: any) {
    return this.eventsService.leaveEvent(id, req.user.id);
  }
}
