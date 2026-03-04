// ============================================
// 결제 요청 데이터 형식 (DTO)
// 고객이 계약 후 결제할 때 보내야 하는 정보
//
// 쉽게 말하면: "이 계약의 계약금을 결제합니다" 라는 신청서
// ============================================

import { IsNotEmpty, IsString, IsOptional } from 'class-validator';

export class CreatePaymentDto {
  @IsString()
  @IsNotEmpty()
  contractId: string;       // 결제할 계약 ID

  @IsOptional()
  @IsString()
  method?: string;          // 결제 수단 (CARD, BANK_TRANSFER, EASY_PAY 등)
}
