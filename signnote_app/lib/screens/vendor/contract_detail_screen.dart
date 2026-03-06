import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';

// ============================================
// 업체용 계약 상세보기 화면 (2차 디자인)
//
// 디자인 참고: 8.고객용-계약 상세보기.jpg 를 업체용으로 적용
// - 상단: ← 품목 카테고리명
// - 계약 내용 >
// - 업체 정보 (본인 업체 정보)
// - 계약 내용 (패키지명, 상세 내용)
// - 계약 금액 (가격, 계약금, 잔금 + 결제 정보)
// - 취소 환불 안내
// - 하단: "다운로드" 버튼
// ============================================

class VendorContractDetailScreen extends StatelessWidget {
  final Map<String, dynamic> contract;
  final String categoryName;

  const VendorContractDetailScreen({
    super.key,
    required this.contract,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final formattedPrice = NumberFormat('#,###').format(contract['originalPrice'] ?? contract['price'] ?? 0);
    final formattedDeposit = NumberFormat('#,###').format(contract['depositAmount'] ?? 0);
    final formattedRemain = NumberFormat('#,###').format(contract['remainAmount'] ?? 0);

    // 상태 텍스트
    final status = contract['status'] as String? ?? 'CONFIRMED';
    String depositStatusText;
    switch (status) {
      case 'CONFIRMED':
        depositStatusText = '(결제 완료)';
        break;
      case 'CANCEL_REQUESTED':
        depositStatusText = '(취소 요청)';
        break;
      case 'CANCELLED':
        depositStatusText = '(취소됨)';
        break;
      default:
        depositStatusText = '(대기중)';
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          categoryName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "계약 내용 >"
            const Row(
              children: [
                Text('계약 내용', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20),
              ],
            ),
            const SizedBox(height: 16),

            // 고객 정보 섹션
            _buildSectionCard(
              title: '고객 정보',
              children: [
                _buildInfoLine('고객명', contract['customerName'] ?? '-'),
                _buildInfoLine('주소', contract['customerAddress'] ?? '-'),
                _buildInfoLine('연락처', contract['customerPhone'] ?? '-'),
              ],
            ),
            const SizedBox(height: 12),

            // 계약 내용 섹션
            _buildSectionCard(
              title: '계약 내용',
              children: [
                _buildInfoLine('패키지명', contract['productName'] ?? '-'),
                _buildInfoLine('상세 내용', contract['description'] ?? '-'),
              ],
            ),
            const SizedBox(height: 12),

            // 계약 금액 섹션
            _buildSectionCard(
              title: '계약 금액',
              children: [
                _buildInfoLine('가격', '$formattedPrice원'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 16),
                    const Text('계약금 : ', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                    Expanded(
                      child: Text(
                        '$formattedDeposit원 $depositStatusText',
                        style: const TextStyle(fontSize: 14, color: AppColors.priceRed, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildInfoLine('잔금', '$formattedRemain원'),
              ],
            ),
            const SizedBox(height: 24),

            // 취소 환불 안내
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '계약금 먼저 결제 되며, 취소 환불 조항에 동의합니다.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '지금 결제 하시면 모두 결제되는 것이 아니라 계약금만 결제되며, 잔금은 해당 업체와 직접 결제하시면 됩니다.\n취소 지정 기간 이후 취소 건은 계약금 환불은 어렵습니다.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      // 하단: "다운로드" 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('계약서 다운로드 기능은 준비 중입니다')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vendor,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            child: const Text('다운로드'),
          ),
        ),
      ),
    );
  }

  // 섹션 카드 (제목 + 내용)
  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목 (회색 배경)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          // 내용
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // 정보 행
  Widget _buildInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 0, child: Container()),
          Text('$label : $value', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6)),
        ],
      ),
    );
  }
}
