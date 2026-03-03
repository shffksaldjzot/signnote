// ============================================
// 행사 입장 요청 데이터 형식 (DTO)
// 앱에서 참여 코드를 입력해서 행사에 입장할 때 사용
// ============================================

import { IsString, Length, Matches } from 'class-validator';

export class EnterEventDto {
  @IsString()
  @Length(6, 6, { message: '참여 코드는 숫자 6자리입니다' })
  @Matches(/^\d{6}$/, { message: '참여 코드는 숫자만 입력 가능합니다' })
  entryCode: string;
}
