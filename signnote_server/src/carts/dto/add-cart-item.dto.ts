// ============================================
// 장바구니 추가 요청 데이터 형식 (DTO)
// 고객이 상품을 장바구니에 담을 때 보내야 하는 정보
// ============================================

import { IsNotEmpty, IsString, IsInt, IsOptional, Min } from 'class-validator';

export class AddCartItemDto {
  @IsString()
  @IsNotEmpty({ message: '상품 ID를 입력해 주세요' })
  productId: string;    // 장바구니에 담을 상품 ID

  @IsString()
  @IsNotEmpty({ message: '행사 ID를 입력해 주세요' })
  eventId: string;      // 해당 행사 ID

  @IsOptional()
  @IsInt()
  @Min(1)
  quantity?: number;    // 수량 (기본 1)
}
