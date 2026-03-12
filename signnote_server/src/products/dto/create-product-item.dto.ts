// ============================================
// 상세 품목(ProductItem) 생성 DTO - 2뎁스
// 업체가 패키지(A패키지, B패키지 등)를 등록할 때 사용
// ============================================

import {
  IsArray,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class CreateProductItemDto {
  @IsString()
  @IsNotEmpty({ message: '패키지명을 입력해 주세요' })
  name: string;                           // 패키지명 (예: "A 패키지", "풀 패키지")

  @IsArray()
  @IsString({ each: true })
  housingTypes: string[];                 // 적용 타입 ["84A","84B"]

  @IsOptional()
  @IsString()
  description?: string;                   // 상세 설명

  @IsInt()
  @Min(0, { message: '가격은 0원 이상이어야 합니다' })
  price: number;                          // 가격 (원)

  @IsOptional()
  @IsString()
  image?: string;                         // 이미지 URL (대표 1장, 하위호환)

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];                      // 이미지 URL 배열 (최대 5장)
}
