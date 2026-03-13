import 'package:flutter/material.dart';
import '../../config/theme.dart';

// ============================================
// AppCard - 카드 형태 컨테이너
//
// 디자인: 흰 배경 + 연한 테두리 + 둥근 모서리
// 행사 카드, 상품 카드, 계약 카드 등에서 사용
//
// 사용 예시:
//   AppCard(child: Text('내용'))
//   AppCard(onTap: () {}, child: Text('누를 수 있는 카드'))
//   AppCard.dark(child: Text('총 견적'))  → 어두운 배경 카드
// ============================================

class AppCard extends StatelessWidget {
  final Widget child;             // 카드 안에 넣을 내용
  final VoidCallback? onTap;      // 카드 눌렀을 때 (선택사항)
  final EdgeInsetsGeometry? padding;  // 안쪽 여백
  final Color backgroundColor;   // 배경색
  final Color borderColor;        // 테두리 색

  // 기본 카드 (흰 배경 + 연한 테두리)
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = AppColors.white,
    this.borderColor = AppColors.border,
  });

  // 어두운 카드 (총 견적, 계약금 결제 금액 바 등)
  const AppCard.dark({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.backgroundColor = AppColors.summaryBar,
    this.borderColor = AppColors.summaryBar,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
        // 카드 그림자 (은은한 입체감)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    // 누를 수 있는 카드면 InkWell로 감싸기
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
