import 'package:flutter/material.dart';

// ============================================
// Signnote 앱 테마 설정
// 디자인 가이드라인에서 추출한 색상, 글꼴, 버튼 스타일
// ============================================

/// 앱에서 사용하는 색상 모음
class AppColors {
  // 주요 색상 (Primary)
  static const Color primary = Color(0xFF4A90FF);       // 파란색 - 로고, 고객용 버튼, 활성 탭
  static const Color primaryDark = Color(0xFF000000);    // 검정색 - 업체/주관사용 버튼
  static const Color white = Color(0xFFFFFFFF);          // 흰색 - 배경
  static const Color background = Color(0xFFF5F5F5);     // 연한 회색 - 카드 배경

  // 텍스트 색상
  static const Color textPrimary = Color(0xFF000000);    // 검정 - 주요 텍스트
  static const Color textSecondary = Color(0xFF666666);  // 회색 - 보조 텍스트
  static const Color textHint = Color(0xFF999999);       // 연한 회색 - 힌트 텍스트

  // 강조 색상
  static const Color priceRed = Color(0xFFFF3B5C);       // 빨간색 - 가격, 취소 요청
  static const Color badgeRed = Color(0xFFFF3B5C);       // 빨간색 - D-day 뱃지, 장바구니 숫자
  static const Color summaryBar = Color(0xFF2C2C2C);     // 진한 검정 - 총 견적/금액 바

  // 상태 색상
  static const Color success = Color(0xFF4CAF50);        // 초록 - 성공
  static const Color warning = Color(0xFFFFC107);        // 노랑 - 경고

  // 구분선/테두리
  static const Color border = Color(0xFFE0E0E0);         // 연한 회색 - 구분선
  static const Color divider = Color(0xFFF0F0F0);        // 더 연한 회색 - 얇은 구분선
}

/// 앱에서 사용하는 테마 (MaterialApp에 적용)
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // 기본 색상 설정
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      // 배경색
      scaffoldBackgroundColor: AppColors.white,
      // 앱바 (상단 헤더) 스타일
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,          // 흰색 배경
        foregroundColor: AppColors.textPrimary,     // 검정 글씨
        elevation: 0,                               // 그림자 없음
        centerTitle: true,                           // 제목 가운데 정렬
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,               // 약간 굵게
        ),
      ),
      // 파란 버튼 스타일 (고객용 기본 버튼)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,        // 파란 배경
          foregroundColor: AppColors.white,           // 흰 글씨
          minimumSize: const Size(double.infinity, 52), // 가로 꽉 차게, 높이 52
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),  // 둥근 모서리
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // 텍스트 입력 필드 스타일
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
      ),
      // 하단 네비게이션 바 스타일
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,        // 선택된 탭: 파란색
        unselectedItemColor: AppColors.textSecondary, // 미선택 탭: 회색
        type: BottomNavigationBarType.fixed,
      ),
      // 카드 스타일
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      // 구분선 스타일
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
