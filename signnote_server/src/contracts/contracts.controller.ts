// ============================================
// 계약 컨트롤러 (Contracts Controller)
//
// API 목록:
//   POST   /api/v1/contracts              → 계약 생성 (고객)
//   GET    /api/v1/contracts              → 내 계약 목록 (고객)
//   GET    /api/v1/contracts/vendor       → 내 상품 계약 목록 (업체)
//   GET    /api/v1/contracts/event/:eventId → 행사별 계약 목록 (주관사)
//   GET    /api/v1/contracts/:id          → 계약 상세
//   PUT    /api/v1/contracts/:id/cancel   → 계약 취소
// ============================================

import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ContractsService } from './contracts.service';
import { CreateContractDto } from './dto/create-contract.dto';
import { JwtAuthGuard, RolesGuard, Roles } from '../auth/roles.guard';

@Controller('contracts')
export class ContractsController {
  constructor(private readonly contractsService: ContractsService) {}

  // 계약 생성 (고객: 장바구니에서 계약 신청)
  @UseGuards(JwtAuthGuard)
  @Post()
  async create(@Request() req: any, @Body() dto: CreateContractDto) {
    return this.contractsService.createContracts(req.user.id, dto);
  }

  // 내 계약 목록 (고객용)
  // ?eventId=xxx 로 행사별 필터 가능
  @UseGuards(JwtAuthGuard)
  @Get()
  async findMyContracts(
    @Request() req: any,
    @Query('eventId') eventId?: string,
  ) {
    return this.contractsService.findByCustomer(req.user.id, eventId);
  }

  // 내 상품의 계약 목록 (업체용)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('VENDOR')
  @Get('vendor')
  async findVendorContracts(
    @Request() req: any,
    @Query('eventId') eventId?: string,
  ) {
    return this.contractsService.findByVendor(req.user.id, eventId);
  }

  // 행사별 전체 계약 목록 (주관사용)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ORGANIZER', 'ADMIN')
  @Get('event/:eventId')
  async findByEvent(@Param('eventId') eventId: string) {
    return this.contractsService.findByEvent(eventId);
  }

  // 계약 상세 조회
  @UseGuards(JwtAuthGuard)
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.contractsService.findOne(id);
  }

  // 계약 취소
  @UseGuards(JwtAuthGuard)
  @Put(':id/cancel')
  async cancel(@Request() req: any, @Param('id') id: string) {
    return this.contractsService.cancel(id, req.user.id);
  }
}
