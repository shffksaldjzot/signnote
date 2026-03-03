import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';

// ============================================
// PriceText - 가격 표시 위젯
//
// 디자인: "가격 : 700,000원" (가격 부분만 빨간색)
//
// 사용 예시:
//   PriceText(label: '가격', price: 700000)
//   PriceText(label: '계약금', price: 420000)
//   PriceText(label: '잔금', price: 980000, priceColor: AppColors.textPrimary)
// ============================================

class PriceText extends StatelessWidget {
  final String label;      // 앞에 붙는 라벨 (예: "가격", "계약금")
  final int price;         // 금액 (원 단위)
  final Color priceColor;  // 금액 색상 (기본: 빨간색)
  final double fontSize;   // 글자 크기

  const PriceText({
    super.key,
    required this.label,
    required this.price,
    this.priceColor = AppColors.priceRed,   // 기본: 빨간색
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    // 숫자에 콤마 넣기 (700000 → "700,000")
    final formattedPrice = NumberFormat('#,###').format(price);

    return RichText(
      text: TextSpan(
        children: [
          // "가격 : " 부분 (검정색)
          TextSpan(
            text: '$label : ',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          // "700,000원" 부분 (빨간색)
          TextSpan(
            text: '$formattedPrice원',
            style: TextStyle(
              color: priceColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
