// ============================================
// 상품(품목) 생성 요청 데이터 형식 (DTO)
// 협력업체가 품목을 등록할 때 보내야 하는 정보
// ============================================

import {
  IsArray,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class CreateProductDto {
  @IsString()
  @IsNotEmpty({ message: '상품명을 입력해 주세요' })
  name: string;                           // 상품명 (예: "줄눈 A 패키지")

  @IsString()
  @IsNotEmpty({ message: '품목 카테고리를 입력해 주세요' })
  category: string;                       // 카테고리 (예: "줄눈", "나노코팅")

  @IsString()
  @IsNotEmpty()
  eventId: string;                        // 소속 행사 ID

  @IsOptional()
  @IsString()
  vendorName?: string;                    // 업체명 (업체 등록 시)

  @IsArray()
  @IsString({ each: true })
  housingTypes: string[];                 // 적용 타입 ["84A","84B"]

  @IsOptional()
  @IsString()
  image?: string;                         // 상품 이미지 URL

  @IsOptional()
  @IsString()
  description?: string;                   // 상품 설명 (예: "욕실2바닥+현관+안방...")

  @IsInt()
  @Min(0, { message: '가격은 0원 이상이어야 합니다' })
  price: number;                          // 가격 (원)

  @IsOptional()
  @IsNumber()
  commissionRate?: number;                // 수수료율 (0~1, 주관사용)

  @IsOptional()
  @IsInt()
  participationFee?: number;              // 참가비 (주관사용)
}
