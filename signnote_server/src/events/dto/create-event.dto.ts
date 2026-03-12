// ============================================
// 행사 생성 요청 데이터 형식 (DTO)
// 주관사가 새 행사를 만들 때 보내야 하는 정보
// ============================================

import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class CreateEventDto {
  @IsString()
  @IsNotEmpty({ message: '행사 제목을 입력해 주세요' })
  title: string;                          // 행사명 (예: "창원 자이 사전 박람회")

  @IsOptional()
  @IsString()
  contractMethod?: string;                // 계약 방식

  @IsOptional()
  @IsString()
  siteName?: string;                      // 현장명

  @IsOptional()
  @IsInt()
  @Min(1, { message: '세대수는 1 이상이어야 합니다' })
  unitCount?: number;                     // 세대수 (선택)

  @IsOptional()
  @IsDateString({}, { message: '올바른 날짜 형식이 아닙니다' })
  moveInDate?: string;                    // 입주 예정일

  @IsArray()
  @IsString({ each: true })
  housingTypes: string[];                 // 적용 타입 ["74A","74B","84A","84B"]

  @IsOptional()
  @IsString()
  coverImage?: string;                    // 커버 이미지 URL

  @IsDateString()
  startDate: string;                      // 행사 시작일

  @IsDateString()
  endDate: string;                        // 행사 종료일

  @IsOptional()
  @IsDateString()
  cancelDeadlineStart?: string;           // 취소 지정 기간 시작

  @IsOptional()
  @IsDateString()
  cancelDeadlineEnd?: string;             // 취소 지정 기간 종료

  @IsOptional()
  @IsBoolean()
  allowOnlineContract?: boolean;          // 취소기간에도 온라인 계약 허용?

  @IsOptional()
  @IsNumber()
  depositRate?: number;                   // 계약금 비율 (0.0 ~ 1.0, 기본 0.3 = 30%)

  @IsOptional()
  paymentSchedule?: any;                  // 결제 일정 JSON (계약금/중도금/잔금 요율+날짜)
}
