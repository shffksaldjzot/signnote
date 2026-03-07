import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================
// Signnote 앱 테마 설정 (2차 디자인)
// 폰트: Inter / 역할별 메인컬러 분리
// ============================================

/// 앱에서 사용하는 색상 모음
class AppColors {
  // ── 역할별 메인컬러 ──
  static const Color customer = Color(0xFF2D6EFF);    // 고객 메인 (파란색)
  static const Color organizer = Color(0xFFFF6A00);   // 주관사 메인 (주황색)
  static const Color vendor = Color(0xFF000000);       // 협력업체 메인 (검정색)

  // ── 기존 호환용 (고객 파란색 = primary) ──
  static const Color primary = Color(0xFF2D6EFF);
  static const Color primaryDark = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F5);

  // 텍스트 색상
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);

  // 강조 색상
  static const Color priceRed = Color(0xFFFF3B5C);
  static const Color badgeRed = Color(0xFFFF3B5C);
  static const Color summaryBar = Color(0xFF2C2C2C);

  // 상태 색상
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);

  // 구분선/테두리
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F0);
}

/// 앱에서 사용하는 테마 (MaterialApp에 적용)
class AppTheme {
  static ThemeData get lightTheme {
    // Inter 폰트 + Noto Sans KR 한글 폴백 (한글 깨짐 방지)
    final textTheme = GoogleFonts.interTextTheme().apply(
      fontFamilyFallback: ['Noto Sans KR', 'sans-serif'],
    );

    return ThemeData(
      // 기본 색상 설정
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      // Inter 폰트 적용
      textTheme: textTheme,
      // 배경색
      scaffoldBackgroundColor: AppColors.white,
      // 앱바 (상단 헤더) 스타일
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      // 파란 버튼 스타일 (고객용 기본 버튼)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
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
        hintStyle: GoogleFonts.inter(
          color: AppColors.textHint,
          fontSize: 14,
        ),
      ),
      // 하단 네비게이션 바 스타일
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
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
      // 다이얼로그 스타일
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
      // SnackBar 스타일
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.summaryBar,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      // 구분선 스타일
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
