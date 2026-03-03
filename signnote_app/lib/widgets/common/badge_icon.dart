import 'package:flutter/material.dart';
import '../../config/theme.dart';

// ============================================
// BadgeIcon - 빨간 숫자 뱃지가 달린 아이콘
//
// 디자인: 아이콘 오른쪽 위에 빨간 동그라미 + 숫자
// 예시: 장바구니 아이콘에 "2" 뱃지, D-day 뱃지
//
// 사용 예시:
//   BadgeIcon(icon: Icons.shopping_cart, count: 2)
// ============================================

class BadgeIcon extends StatelessWidget {
  final IconData icon;       // 아이콘 모양
  final int count;           // 뱃지에 표시할 숫자
  final Color iconColor;     // 아이콘 색상
  final double iconSize;     // 아이콘 크기

  const BadgeIcon({
    super.key,
    required this.icon,
    required this.count,
    this.iconColor = AppColors.textSecondary,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    // 숫자가 0 이하면 뱃지 없이 아이콘만 표시
    if (count <= 0) {
      return Icon(icon, color: iconColor, size: iconSize);
    }

    return Badge(
      label: Text(
        count > 99 ? '99+' : '$count',  // 100 이상이면 "99+"로 표시
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.badgeRed,
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}

// ============================================
// DdayBadge - D-day 뱃지
//
// 디자인: 빨간 배경에 "D-3" 흰 글씨
// 행사 카드 아래에 표시됨
//
// 사용 예시:
//   DdayBadge(daysLeft: 3)   → "D-3"
//   DdayBadge(daysLeft: 0)   → "D-Day"
//   DdayBadge(daysLeft: -1)  → "종료"
// ============================================

class DdayBadge extends StatelessWidget {
  final int daysLeft;   // 남은 일수

  const DdayBadge({
    super.key,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    // 표시할 텍스트 결정
    String text;
    Color bgColor;

    if (daysLeft > 0) {
      text = 'D-$daysLeft';
      bgColor = AppColors.badgeRed;           // 빨간색
    } else if (daysLeft == 0) {
      text = 'D-Day';
      bgColor = AppColors.badgeRed;           // 빨간색
    } else {
      text = '종료';
      bgColor = AppColors.textSecondary;      // 회색
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
