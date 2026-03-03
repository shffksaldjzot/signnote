// ============================================
// 로그인 요청 데이터 형식 (DTO)
// 앱에서 로그인할 때 보내야 하는 정보
// ============================================

import { IsEmail, IsString, MinLength } from 'class-validator';

export class LoginDto {
  @IsEmail({}, { message: '올바른 이메일 형식이 아닙니다' })
  email: string;

  @IsString()
  @MinLength(6, { message: '비밀번호는 6자 이상이어야 합니다' })
  password: string;
}
