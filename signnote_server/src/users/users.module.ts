// ============================================
// 사용자 모듈 (Users Module)
// 사용자 관련 서비스를 묶어서 등록하는 파일
// ============================================

import { Module } from '@nestjs/common';
import { UsersService } from './users.service';

@Module({
  providers: [UsersService],
  exports: [UsersService],     // 다른 모듈(Auth 등)에서 사용 가능하게 내보내기
})
export class UsersModule {}
