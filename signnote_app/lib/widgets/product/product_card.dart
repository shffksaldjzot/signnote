import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';

// ============================================
// ProductCard - 상품(품목) 카드 위젯
//
// 디자인: 썸네일 이미지 + 업체명 + 상품명 + 설명 + 가격 + 버튼
//
// 고객용: 상세보기 버튼 + 장바구니 추가(+) 또는 선택됨(✓)
// 업체용: 수정(연필) 아이콘
//
// 사용 예시:
//   ProductCard(
//     vendorName: '앤드 디자인',
//     productName: '줄눈 A 패키지',
//     description: '욕실2바닥+현관+안방...',
//     price: 700000,
//     imageUrl: '...',
//     onDetailTap: () {},
//     onAddToCart: () {},
//   )
// ============================================

class ProductCard extends StatelessWidget {
  final String vendorName;         // 업체명
  final String productName;        // 상품명
  final String? description;       // 상품 설명
  final int price;                 // 가격 (원)
  final String? imageUrl;          // 상품 이미지 URL
  final bool isInCart;             // 장바구니에 담겨있는지 (✓ 표시용)
  final VoidCallback? onDetailTap; // 상세보기 눌렀을 때
  final VoidCallback? onAddToCart; // 장바구니 추가 눌렀을 때 (고객용)
  final VoidCallback? onEditTap;   // 수정 눌렀을 때 (업체용)

  const ProductCard({
    super.key,
    required this.vendorName,
    required this.productName,
    this.description,
    required this.price,
    this.imageUrl,
    this.isInCart = false,
    this.onDetailTap,
    this.onAddToCart,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedPrice = NumberFormat('#,###').format(price);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽: 썸네일 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: AppColors.background,
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : const Icon(
                      Icons.image_outlined,
                      color: AppColors.textHint,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // 오른쪽: 상품 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 업체명 + 상세보기 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vendorName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (onDetailTap != null)
                      GestureDetector(
                        onTap: onDetailTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            '상세보기',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // 상품명 (굵게)
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                // 설명 (있으면 표시)
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                // 가격 + 장바구니/수정 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 가격 (빨간색)
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: '가격 : ',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: '$formattedPrice원',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.priceRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 오른쪽 버튼 (장바구니 추가 or 수정)
                    if (onAddToCart != null)
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isInCart
                                ? AppColors.primary   // 담김: 파란색 ✓
                                : AppColors.white,    // 안 담김: 흰색 +
                            border: Border.all(
                              color: isInCart
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Icon(
                            isInCart ? Icons.check : Icons.add,
                            size: 18,
                            color: isInCart
                                ? AppColors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    if (onEditTap != null)
                      GestureDetector(
                        onTap: onEditTap,
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
