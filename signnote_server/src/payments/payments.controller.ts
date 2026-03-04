// ============================================
// 결제 컨트롤러 (Payments Controller)
//
// API 목록:
//   POST   /api/v1/payments              → 결제 요청 (고객)
//   POST   /api/v1/payments/webhook      → PG 결제 완료 콜백 (공개)
//   GET    /api/v1/payments              → 내 결제 목록 (로그인)
//   GET    /api/v1/payments/:id          → 결제 상세 (로그인)
//   PUT    /api/v1/payments/:id/refund   → 환불 요청 (고객)
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
import { PaymentsService } from './payments.service';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { JwtAuthGuard } from '../auth/roles.guard';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  // 결제 요청 (고객: 계약금 결제)
  @UseGuards(JwtAuthGuard)
  @Post()
  async create(@Request() req: any, @Body() dto: CreatePaymentDto) {
    return this.paymentsService.createPayment(req.user.id, dto);
  }

  // PG 결제 완료 콜백 (Webhook)
  // PG사에서 결제 결과를 알려주는 엔드포인트
  // 공개 API (인증 불필요 — PG 서버에서 호출)
  @Post('webhook')
  async webhook(@Body() body: { pgTransactionId: string; status: string }) {
    return this.paymentsService.handleWebhook(body.pgTransactionId, body.status);
  }

  // 내 결제 목록
  // ?eventId=xxx 로 행사별 필터 가능
  @UseGuards(JwtAuthGuard)
  @Get()
  async findMyPayments(
    @Request() req: any,
    @Query('eventId') eventId?: string,
  ) {
    return this.paymentsService.findMyPayments(req.user.id, eventId);
  }

  // 결제 상세 조회
  @UseGuards(JwtAuthGuard)
  @Get(':id')
  async findOne(@Request() req: any, @Param('id') id: string) {
    return this.paymentsService.findOne(id, req.user.id);
  }

  // 환불 요청
  @UseGuards(JwtAuthGuard)
  @Put(':id/refund')
  async refund(@Request() req: any, @Param('id') id: string) {
    return this.paymentsService.requestRefund(id, req.user.id);
  }
}
