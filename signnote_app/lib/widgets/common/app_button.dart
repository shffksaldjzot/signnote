import 'package:flutter/material.dart';
import '../../config/theme.dart';

// ============================================
// AppButton - 앱 전체에서 쓰는 공통 버튼
//
// 사용 예시:
//   AppButton(text: '로그인', onPressed: () {})          → 파란 버튼 (고객용)
//   AppButton.black(text: '입장하기', onPressed: () {})   → 검정 버튼 (업체/주관사용)
//   AppButton(text: '장바구니', badgeCount: 2, ...)       → 뱃지 달린 버튼
// ============================================

class AppButton extends StatelessWidget {
  final String text;              // 버튼에 표시할 글자
  final VoidCallback? onPressed;  // 버튼 눌렀을 때 실행할 동작
  final Color backgroundColor;   // 배경색
  final Color textColor;          // 글자색
  final int? badgeCount;          // 뱃지 숫자 (장바구니 개수 등, 없으면 null)
  final bool isLoading;           // 로딩 중인지 (로딩이면 빙글빙글 표시)
  final bool enabled;             // 버튼 활성화 여부

  // 기본 생성자 - 파란 버튼 (고객용 기본)
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor = AppColors.primary,    // 기본: 파란색
    this.textColor = AppColors.white,            // 기본: 흰 글씨
    this.badgeCount,
    this.isLoading = false,
    this.enabled = true,
  });

  // 검정 버튼 생성자 (업체/주관사용)
  const AppButton.black({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor = AppColors.primaryDark, // 검정색
    this.textColor = AppColors.white,
    this.badgeCount,
    this.isLoading = false,
    this.enabled = true,
  });

  // 테두리만 있는 버튼 (상세보기 등)
  const AppButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor = AppColors.white,       // 흰 배경
    this.textColor = AppColors.textPrimary,        // 검정 글씨
    this.badgeCount,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // 테두리 버튼인지 확인 (배경이 흰색이면 테두리 버튼)
    final bool isOutlined = backgroundColor == AppColors.white;

    return SizedBox(
      width: double.infinity,   // 가로 꽉 차게
      height: 52,               // 높이 52 (디자인 기준)
      child: ElevatedButton(
        onPressed: (enabled && !isLoading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? backgroundColor : AppColors.border,
          foregroundColor: textColor,
          elevation: 0,           // 그림자 없음
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isOutlined
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        ),
        child: _buildChild(),
      ),
    );
  }

  // 버튼 내부 내용 (텍스트 + 뱃지 or 로딩)
  Widget _buildChild() {
    // 로딩 중이면 빙글빙글 표시
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: textColor,
        ),
      );
    }

    // 뱃지가 있으면 텍스트 + 뱃지
    if (badgeCount != null && badgeCount! > 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          // 빨간 동그라미 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: const BoxDecoration(
              color: AppColors.badgeRed,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$badgeCount',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    // 기본: 텍스트만
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}
