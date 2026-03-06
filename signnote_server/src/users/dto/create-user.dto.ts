// ============================================
// 회원가입 요청 데이터 형식 (DTO)
// 앱에서 회원가입할 때 보내야 하는 정보들
// ============================================

import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';

// 사용자 역할 (Prisma의 Role과 동일)
export enum RoleEnum {
  CUSTOMER = 'CUSTOMER',       // 고객
  VENDOR = 'VENDOR',           // 협력업체
  ORGANIZER = 'ORGANIZER',     // 주관사
}

export class CreateUserDto {
  @IsEmail({}, { message: '올바른 이메일 형식이 아닙니다' })
  email: string;

  @IsString()
  @MinLength(6, { message: '비밀번호는 6자 이상이어야 합니다' })
  password: string;

  @IsString()
  @IsNotEmpty({ message: '이름을 입력해 주세요' })
  name: string;

  @IsString()
  @IsNotEmpty({ message: '전화번호를 입력해 주세요' })
  phone: string;

  @IsEnum(RoleEnum, { message: '올바른 역할을 선택해 주세요 (CUSTOMER, VENDOR, ORGANIZER)' })
  role: RoleEnum;

  @IsOptional()
  @IsString()
  representativeName?: string;  // 대표자 성명 (업체/주관사)

  @IsOptional()
  @IsString()
  businessNumber?: string;     // 사업자번호 (업체/주관사)

  @IsOptional()
  @IsString()
  businessAddress?: string;    // 사업장 주소 (업체/주관사)

  @IsOptional()
  @IsString()
  businessLicenseImage?: string;  // 사업자등록증 이미지 URL (업체/주관사)

  @IsOptional()
  @IsString()
  bankAccount?: string;        // 계좌정보 (업체만)
}
