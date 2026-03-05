// ============================================
// 주관사용 품목 생성 DTO
// 주관사가 행사에 품목(카테고리)을 등록할 때 사용
// 품목명, 참가비, 수수료, 이미지만 입력
// ============================================

import {
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class CreateProductOrganizerDto {
  @IsString()
  @IsNotEmpty({ message: '품목명을 입력해 주세요' })
  name: string;                           // 품목명 (예: "줄눈", "나노코팅")

  @IsString()
  @IsNotEmpty()
  eventId: string;                        // 소속 행사 ID

  @IsOptional()
  @IsInt()
  @Min(0)
  participationFee?: number;              // 참가비 (원)

  @IsOptional()
  @IsNumber()
  commissionRate?: number;                // 수수료율 (0~1)

  @IsOptional()
  @IsString()
  image?: string;                         // 품목 설명 이미지 URL
}
