import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';

// ============================================
// ContractCard - 계약 카드 위젯
//
// 디자인에서 사용되는 곳:
//   고객용 계약함: 상품정보 + "계약금 결제 완료" 뱃지 + 가격/계약금/잔금
//   업체용 계약함: 고객정보(동/호/이름/전화) + 상품정보 + 상태 뱃지
//
// 사용 예시:
//   ContractCard.customer(
//     productName: '줄눈 B 패키지',
//     vendorName: '앤드 디자인',
//     price: 1400000,
//     depositAmount: 420000,
//     status: ContractCardStatus.confirmed,
//   )
//   ContractCard.vendor(
//     customerName: '김아무개 님',
//     customerAddress: '창원 자이 201동 1305호',
//     customerPhone: '010-1234-1234',
//     productName: '줄눈 B 패키지',
//     price: 1400000,
//     depositAmount: 420000,
//     status: ContractCardStatus.confirmed,
//   )
// ============================================

/// 계약 상태 종류
enum ContractCardStatus {
  confirmed,       // 계약금 결제 완료
  cancelRequested, // 취소 요청
  cancelled,       // 취소 완료
}

class ContractCard extends StatelessWidget {
  // 공통 정보
  final String productName;        // 상품명
  final String? productDescription; // 상품 설명
  final String? vendorName;        // 업체명
  final int price;                 // 원래 가격
  final int depositAmount;         // 계약금
  final ContractCardStatus status; // 상태
  final VoidCallback? onDetailTap; // 상세보기 눌렀을 때
  final String? category;          // 카테고리 (줄눈 등)

  // 업체용 추가 정보
  final String? customerName;      // 고객명
  final String? customerAddress;   // 고객 주소 (동/호수)
  final String? customerPhone;     // 고객 전화번호

  // 고객용 생성자
  const ContractCard.customer({
    super.key,
    required this.productName,
    this.productDescription,
    this.vendorName,
    required this.price,
    required this.depositAmount,
    required this.status,
    this.onDetailTap,
    this.category,
    this.customerName,
    this.customerAddress,
    this.customerPhone,
  });

  // 업체용 생성자
  const ContractCard.vendor({
    super.key,
    required this.productName,
    this.productDescription,
    this.vendorName,
    required this.price,
    required this.depositAmount,
    required this.status,
    this.onDetailTap,
    this.category,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final remainAmount = price - depositAmount; // 잔금

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 업체용: 고객 정보 + 상태 뱃지
          if (customerAddress != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 고객 주소 + 이름 + 전화번호
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerAddress!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$customerName',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      customerPhone ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // 상태 뱃지
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // 고객용: 상태 뱃지 (오른쪽 위)
          if (customerAddress == null)
            Align(
              alignment: Alignment.topRight,
              child: _buildStatusBadge(),
            ),
          // 업체명
          if (vendorName != null)
            Text(
              vendorName!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
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
          // 상품 설명
          if (productDescription != null) ...[
            const SizedBox(height: 2),
            Text(
              productDescription!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          // 상세보기 버튼
          if (onDetailTap != null) ...[
            GestureDetector(
              onTap: onDetailTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  '상세보기',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // 가격 정보 (오른쪽 정렬)
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 가격
                Text(
                  '가격 : ${formatter.format(price)}원',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                // 계약금 (빨간색)
                Text(
                  '계약금 : ${formatter.format(depositAmount)}원',
                  style: TextStyle(
                    fontSize: 14,
                    color: status == ContractCardStatus.cancelled
                        ? AppColors.textSecondary  // 취소되면 회색 + 취소선
                        : AppColors.priceRed,
                    decoration: status == ContractCardStatus.cancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                // 잔금
                Text(
                  '잔금 : ${formatter.format(status == ContractCardStatus.cancelled ? 0 : remainAmount)}원',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 상태 뱃지 위젯
  Widget _buildStatusBadge() {
    String text;
    Color bgColor;
    Color textColor;

    switch (status) {
      case ContractCardStatus.confirmed:
        text = '계약금 결제 완료';
        bgColor = AppColors.textPrimary;     // 검정 배경
        textColor = AppColors.white;          // 흰 글씨
      case ContractCardStatus.cancelRequested:
        text = '취소 요청';
        bgColor = AppColors.priceRed;         // 빨간 배경
        textColor = AppColors.white;
      case ContractCardStatus.cancelled:
        text = '취소 완료';
        bgColor = AppColors.white;            // 흰 배경
        textColor = AppColors.textSecondary;  // 회색 글씨
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: status == ContractCardStatus.cancelled
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
