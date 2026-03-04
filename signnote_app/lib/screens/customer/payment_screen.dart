import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../services/payment_service.dart';

// ============================================
// 결제 화면
//
// 장바구니에서 계약 생성 후 → 이 화면에서 결제
// - 계약 상품 정보 표시
// - 결제 수단 선택 (카드/계좌이체/간편결제)
// - 결제 금액 (계약금 30%) 표시
// - "결제하기" 버튼 → 테스트 모드에서 바로 완료 처리
// ============================================

class PaymentScreen extends StatefulWidget {
  // 계약 생성 결과 (계약 ID, 상품 정보, 금액 등)
  final List<Map<String, dynamic>> contracts;
  final String eventId;
  final String eventTitle;

  const PaymentScreen({
    super.key,
    required this.contracts,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();

  // 선택된 결제 수단 (기본: 카드)
  String _selectedMethod = 'CARD';
  // 결제 진행 중 여부
  bool _isProcessing = false;

  // 결제 수단 목록
  final List<Map<String, String>> _paymentMethods = [
    {'value': 'CARD', 'label': '신용/체크카드'},
    {'value': 'BANK_TRANSFER', 'label': '계좌이체'},
    {'value': 'EASY_PAY', 'label': '간편결제 (카카오페이 등)'},
  ];

  // 총 품목가 계산
  int get _totalOriginalPrice {
    return widget.contracts.fold(0, (sum, c) {
      // 계약 데이터에서 가격 가져오기
      final price = c['originalPrice'] ?? c['product']?['price'] ?? 0;
      return sum + (price as int);
    });
  }

  // 총 계약금 (결제할 금액)
  int get _totalDepositAmount {
    return widget.contracts.fold(0, (sum, c) {
      final deposit = c['depositAmount'] ?? 0;
      return sum + (deposit as int);
    });
  }

  // 숫자를 콤마 표시 (예: 1400000 → "1,400,000")
  String _formatPrice(int price) {
    return NumberFormat('#,###').format(price);
  }

  // 결제하기
  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    // 각 계약에 대해 결제 요청
    bool allSuccess = true;
    String? errorMsg;

    for (final contract in widget.contracts) {
      final contractId = contract['id'] as String;
      final result = await _paymentService.createPayment(
        contractId: contractId,
        method: _selectedMethod,
      );

      if (!result['success']) {
        allSuccess = false;
        errorMsg = result['error'];
        break;
      }
    }

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (allSuccess) {
      // 결제 완료 다이얼로그
      _showSuccessDialog();
    } else {
      // 결제 실패 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg ?? '결제에 실패했습니다')),
      );
    }
  }

  // 결제 완료 다이얼로그
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text(
              '결제 완료',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.contracts.length}건의 계약금 결제가 완료되었습니다.'),
            const SizedBox(height: 8),
            Text(
              '결제 금액: ${_formatPrice(_totalDepositAmount)}원',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '계약함에서 계약 내역을 확인할 수 있습니다.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();       // 다이얼로그 닫기
              Navigator.of(this.context).pop();   // 결제 화면 닫기
              Navigator.of(this.context).pop(true); // 장바구니 화면 닫기 (계약함으로 이동)
            },
            child: const Text(
              '계약함으로 이동',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppHeader(title: '결제하기'),
      body: Column(
        children: [
          // 스크롤 가능한 영역 (상품 정보 + 결제 수단)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 계약 상품 정보 섹션
                  _buildSectionTitle('계약 상품 정보'),
                  const SizedBox(height: 12),
                  ...widget.contracts.map(_buildContractItem),
                  const SizedBox(height: 24),

                  // 결제 수단 선택 섹션
                  _buildSectionTitle('결제 수단 선택'),
                  const SizedBox(height: 12),
                  ..._paymentMethods.map(_buildPaymentMethodTile),
                  const SizedBox(height: 24),

                  // 결제 금액 요약 (어두운 카드)
                  _buildPaymentSummary(),
                ],
              ),
            ),
          ),

          // 하단: 결제하기 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: AppButton(
              text: '${_formatPrice(_totalDepositAmount)}원 결제하기',
              isLoading: _isProcessing,
              onPressed: _handlePayment,
            ),
          ),
        ],
      ),
    );
  }

  // 섹션 제목
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  // 계약 상품 카드 1개
  Widget _buildContractItem(Map<String, dynamic> contract) {
    // 상품 정보 (계약 데이터 안에 product가 포함되어 있을 수 있음)
    final product = contract['product'] as Map<String, dynamic>?;
    final vendorName = product?['vendorName'] ?? contract['vendorName'] ?? '업체명';
    final productName = product?['name'] ?? contract['productName'] ?? '상품명';
    final price = contract['originalPrice'] ?? product?['price'] ?? 0;
    final deposit = contract['depositAmount'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 업체명
            Text(
              vendorName,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            // 상품명
            Text(
              productName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // 가격
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '가격',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  '${_formatPrice(price)}원',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 계약금
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '계약금(30%)',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  '${_formatPrice(deposit)}원',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.priceRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 결제 수단 선택 타일
  Widget _buildPaymentMethodTile(Map<String, String> method) {
    final isSelected = _selectedMethod == method['value'];

    return GestureDetector(
      onTap: () {
        setState(() => _selectedMethod = method['value']!);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // 라디오 아이콘
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
            const SizedBox(width: 12),
            // 결제 수단 이름
            Text(
              method['label']!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 결제 금액 요약 (어두운 카드)
  Widget _buildPaymentSummary() {
    return AppCard.dark(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryRow('총 품목가', '${_formatPrice(_totalOriginalPrice)}원'),
          const SizedBox(height: 6),
          _buildSummaryRow(
            '계약금(30%)',
            '${_formatPrice(_totalDepositAmount)}원',
          ),
          const Divider(height: 16, color: Colors.white24),
          _buildSummaryRow(
            '결제 금액',
            '${_formatPrice(_totalDepositAmount)}원',
            isBold: true,
            valueColor: AppColors.priceRed,
          ),
        ],
      ),
    );
  }

  // 요약 행 (왼쪽 라벨 + 오른쪽 값)
  Widget _buildSummaryRow(String label, String value, {
    bool isBold = false,
    Color valueColor = Colors.white,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
