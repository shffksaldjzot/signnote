// ============================================
// 계약 생성 요청 데이터 형식 (DTO)
// 고객이 장바구니에서 계약할 때 보내야 하는 정보
//
// 쉽게 말하면: "이 상품을 계약합니다" 라는 신청서
// ============================================

import {
  IsNotEmpty,
  IsString,
  IsOptional,
  IsArray,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

// 개별 계약 항목 (상세 품목 1개 = 계약 1건)
export class ContractItemDto {
  @IsString()
  @IsNotEmpty()
  productId: string;      // 품목 ID (1뎁스)

  @IsOptional()
  @IsString()
  productItemId?: string; // 상세 품목 ID (2뎁스, 실제 계약 패키지)

  @IsString()
  @IsNotEmpty()
  eventId: string;        // 행사 ID
}

// 계약 생성 요청 (여러 상품을 한 번에 계약 가능)
export class CreateContractDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ContractItemDto)
  items: ContractItemDto[];           // 계약할 상품 목록

  @IsOptional()
  @IsString()
  customerAddress?: string;           // 고객 주소 (예: "201동 1305호")

  @IsOptional()
  @IsString()
  customerPhone?: string;             // 고객 전화번호
}
