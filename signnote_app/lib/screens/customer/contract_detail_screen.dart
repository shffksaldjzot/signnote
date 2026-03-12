import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_header.dart';
import '../../utils/image_download.dart';

// ============================================
// 고객용 계약 상세보기 화면
//
// 행사 정보 / 업체 정보 / 고객 정보 / 계약 내용 / 계약 금액 / 환불 안내
// 하단 "다운로드" 버튼 (이미지 파일로 저장)
// ============================================

class CustomerContractDetailScreen extends StatelessWidget {
  final Map<String, dynamic> contract;
  final String categoryName;

  const CustomerContractDetailScreen({
    super.key,
    required this.contract,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat('#,###');
    final originalPrice = contract['originalPrice'] ?? contract['price'] ?? 0;
    final depositAmount = contract['depositAmount'] ?? 0;
    final remainAmount = contract['remainAmount'] ?? (originalPrice - depositAmount);
    final status = contract['status'] ?? 'PENDING';
    final depositLabel = status == 'CONFIRMED' || status == 'CANCEL_REQUESTED'
        ? '${priceFormat.format(depositAmount)}원 (결제 완료)'
        : '${priceFormat.format(depositAmount)}원';

    // 캡처할 영역의 키
    final captureKey = GlobalKey();

    return Scaffold(
      backgroundColor: AppColors.white,
      // 통일된 AppHeader 사용 (뒤로가기 화살표 일관된 디자인)
      appBar: AppHeader(title: categoryName),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: RepaintBoundary(
          key: captureKey,
          child: Container(
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('계약 내용', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                const SizedBox(height: 16),

                // 행사 정보
                _buildSection('행사 정보', [
                  _buildInfoLine('행사명', contract['eventTitle'] ?? '-'),
                  _buildInfoLine('현장명', contract['siteName'] ?? '-'),
                  _buildInfoLine('주관사', contract['organizerName'] ?? '-'),
                ]),
                const SizedBox(height: 16),

                // 업체 정보
                _buildSection('업체 정보', [
                  _buildInfoLine('업체명', contract['vendorName'] ?? '-'),
                  _buildInfoLine('대표자', contract['vendorRepresentative'] ?? '-'),
                  _buildInfoLine('연락처', contract['vendorPhone'] ?? '-'),
                  if ((contract['vendorBusinessNumber'] as String?)?.isNotEmpty == true)
                    _buildInfoLine('사업자번호', contract['vendorBusinessNumber']),
                  if ((contract['vendorBusinessAddress'] as String?)?.isNotEmpty == true)
                    _buildInfoLine('사업장 주소', contract['vendorBusinessAddress']),
                ]),
                const SizedBox(height: 16),

                // 고객 정보 (동/호수/타입 포함 — 모든 역할에서 동일하게 표시)
                _buildSection('고객 정보', [
                  _buildInfoLine('고객명', contract['customerName'] ?? '-'),
                  _buildInfoLine('연락처', contract['customerPhone'] ?? '-'),
                  if ((contract['customerDong'] as String?)?.isNotEmpty == true ||
                      (contract['customerHo'] as String?)?.isNotEmpty == true)
                    _buildInfoLine('동/호수',
                      '${contract['customerDong'] ?? ''}동 ${contract['customerHo'] ?? ''}호'),
                  if ((contract['customerHousingType'] as String?)?.isNotEmpty == true)
                    _buildInfoLine('타입', contract['customerHousingType']),
                ]),
                const SizedBox(height: 16),

                // 계약 내용
                _buildSection('계약 내용', [
                  _buildInfoLine('패키지명', contract['productName'] ?? '-'),
                  if ((contract['description'] as String?)?.isNotEmpty == true)
                    _buildInfoLine('상세 내용', contract['description']),
                ]),
                const SizedBox(height: 16),

                // 계약 금액
                _buildSection('계약 금액', [
                  _buildPriceLine('가격', '${priceFormat.format(originalPrice)}원'),
                  _buildPriceLine('계약금', depositLabel, color: AppColors.priceRed),
                  _buildPriceLine('잔금', '${priceFormat.format(remainAmount)}원'),
                ]),
                const SizedBox(height: 16),

                // 결제 정보 (플레이스홀더)
                _buildSection('결제 정보', [
                  _buildInfoLine('결제 수단', contract['paymentMethod'] ?? '카드결제'),
                  _buildInfoLine('카드/계좌', contract['paymentDetail'] ?? '-'),
                  _buildInfoLine('결제일시', contract['paidAt'] ?? '-'),
                  // 무통장 입금 안내
                  if (contract['paymentMethod'] == '무통장입금' || contract['paymentMethod'] == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F8FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFD6E4FF)),
                        ),
                        child: const Text(
                          '결제 시스템 연동 후 자동으로 표시됩니다.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 24),

                // 환불 안내
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          const Text(
                            '계약금 먼저 결제 되며, 취소 환불 조항에 동의합니다.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '지금 결제 하시면 모두 결제되는 것이 아니라 계약금만 결제되며, 잔금은 해당 업체와 직접 결제하시면 됩니다.\n취소 지정 기간 이후 취소 건은 계약금 환불은 어렵습니다.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 계약 취소 안내
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFFFF6A00)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: const Text(
                          '계약 취소를 원하시는 경우, 해당 협력업체로 직접 연락해 주세요.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF7C4D00), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // 하단: 다운로드 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _downloadAsImage(context, captureKey),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
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

  // 위젯을 이미지로 캡처 → 다운로드
  Future<void> _downloadAsImage(BuildContext context, GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final fileName = '계약서_${contract['productName'] ?? '계약'}_${DateTime.now().millisecondsSinceEpoch}.png';

      await downloadImageBytes(bytes, fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계약서가 다운로드되었습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: $e')),
        );
      }
    }
  }

  // 계약서 내용 위젯 (다운로드용 — 고객/협력업체 공통 사용)
  static Widget buildContractContent(Map<String, dynamic> contract) {
    final format = NumberFormat('#,###');
    final originalPrice = contract['originalPrice'] ?? contract['price'] ?? 0;
    final depositAmount = contract['depositAmount'] ?? 0;
    final remainAmount = contract['remainAmount'] ?? (originalPrice - depositAmount);
    final status = contract['status'] ?? 'PENDING';
    final depositLabel = status == 'CONFIRMED' || status == 'CANCEL_REQUESTED'
        ? '${format.format(depositAmount)}원 (결제 완료)'
        : '${format.format(depositAmount)}원';

    Widget section(String title, List<Widget> children) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
    }

    Widget infoLine(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('$label : $value', style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
      );
    }

    Widget priceLine(String label, String value, {Color? color}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: color ?? AppColors.textPrimary, fontWeight: color != null ? FontWeight.w600 : FontWeight.w400)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          children: [
            Text('계약 내용', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        section('행사 정보', [
          infoLine('행사명', contract['eventTitle'] ?? '-'),
          infoLine('현장명', contract['siteName'] ?? '-'),
          infoLine('주관사', contract['organizerName'] ?? '-'),
        ]),
        const SizedBox(height: 16),
        section('업체 정보', [
          infoLine('업체명', contract['vendorName'] ?? '-'),
          infoLine('대표자', contract['vendorRepresentative'] ?? '-'),
          infoLine('연락처', contract['vendorPhone'] ?? '-'),
          if ((contract['vendorBusinessNumber'] as String?)?.isNotEmpty == true)
            infoLine('사업자번호', contract['vendorBusinessNumber']),
          if ((contract['vendorBusinessAddress'] as String?)?.isNotEmpty == true)
            infoLine('사업장 주소', contract['vendorBusinessAddress']),
        ]),
        const SizedBox(height: 16),
        section('고객 정보', [
          infoLine('고객명', contract['customerName'] ?? '-'),
          infoLine('연락처', contract['customerPhone'] ?? '-'),
          if ((contract['customerDong'] as String?)?.isNotEmpty == true ||
              (contract['customerHo'] as String?)?.isNotEmpty == true)
            infoLine('동/호수', '${contract['customerDong'] ?? ''}동 ${contract['customerHo'] ?? ''}호'),
          if ((contract['customerHousingType'] as String?)?.isNotEmpty == true)
            infoLine('타입', contract['customerHousingType']),
        ]),
        const SizedBox(height: 16),
        section('계약 내용', [
          infoLine('패키지명', contract['productName'] ?? '-'),
          if ((contract['description'] as String?)?.isNotEmpty == true)
            infoLine('상세 내용', contract['description']),
        ]),
        const SizedBox(height: 16),
        section('계약 금액', [
          priceLine('가격', '${format.format(originalPrice)}원'),
          priceLine('계약금', depositLabel, color: AppColors.priceRed),
          priceLine('잔금', '${format.format(remainAmount)}원'),
        ]),
        const SizedBox(height: 16),
        section('결제 정보', [
          infoLine('결제 수단', contract['paymentMethod'] ?? '카드결제'),
          infoLine('카드/계좌', contract['paymentDetail'] ?? '-'),
          infoLine('결제일시', contract['paidAt'] ?? '-'),
        ]),
        const SizedBox(height: 24),
        // 환불 안내
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('계약금 먼저 결제 되며, 취소 환불 조항에 동의합니다.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 8),
              Text('지금 결제 하시면 모두 결제되는 것이 아니라 계약금만 결제되며, 잔금은 해당 업체와 직접 결제하시면 됩니다.\n취소 지정 기간 이후 취소 건은 계약금 환불은 어렵습니다.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  // 섹션 카드
  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      // 글씨를 더 진하게 — 연한 회색 대신 진한 색상 사용
      child: Text('$label : $value', style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
    );
  }

  Widget _buildPriceLine(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: color ?? AppColors.textPrimary, fontWeight: color != null ? FontWeight.w600 : FontWeight.w400)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
