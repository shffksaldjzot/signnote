import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/common/app_button.dart';
import '../../services/product_service.dart';
import '../../utils/number_formatter.dart';

// ============================================
// 주관사용 품목 추가 화면
//
// 디자인 참고: 5.주관사용-품목 상세.jpg
// - 상단: ← "품목 추가하기" 헤더
// - "판매 품목 추가 >"
// - 품목명 입력 (예: 줄눈 / 나노코팅 등)
// - 참가비 입력 (원)
// - 수수료 입력 (%)
// - 품목 설명 이미지 업로드
// - "추가하기" 버튼
// ============================================

class OrganizerProductAddScreen extends StatefulWidget {
  final String eventId; // 품목을 추가할 행사 ID
  final Map<String, dynamic>? product; // 수정 시 기존 데이터 (null이면 새 등록)

  const OrganizerProductAddScreen({
    super.key,
    required this.eventId,
    this.product,
  });

  @override
  State<OrganizerProductAddScreen> createState() =>
      _OrganizerProductAddScreenState();
}

class _OrganizerProductAddScreenState extends State<OrganizerProductAddScreen> {
  late final TextEditingController _nameController;        // 품목명
  late final TextEditingController _feeController;         // 참가비
  late final TextEditingController _commissionController;  // 수수료
  late final TextEditingController _depositRateController; // 계약금 비율
  bool _isSubmitting = false;

  // 수정 모드인지 여부
  bool get _isEditMode => widget.product != null;

  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    // 수정 모드면 기존 데이터로 채우기
    _nameController = TextEditingController(
      text: widget.product?['name'] ?? '',
    );
    final fee = widget.product?['participationFee'] as int? ?? 0;
    _feeController = TextEditingController(
      text: fee > 0 ? formatWithComma(fee) : '',
    );
    final rate = widget.product?['commissionRate'];
    final ratePercent = rate is num ? (rate * 100).toStringAsFixed(0) : '';
    _commissionController = TextEditingController(text: ratePercent);
    // 계약금 비율 (null이면 행사 기본값 사용)
    final depositRate = widget.product?['depositRate'];
    final depositPercent = depositRate is num ? (depositRate * 100).toStringAsFixed(0) : '';
    _depositRateController = TextEditingController(text: depositPercent);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    _commissionController.dispose();
    _depositRateController.dispose();
    super.dispose();
  }

  // 품목 등록/수정 API 호출
  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('품목명을 입력해 주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final fee = parseCommaNumber(_feeController.text.trim());
    final commission = double.tryParse(_commissionController.text.trim()) ?? 0;
    // 계약금 비율: 입력값이 있으면 % → 소수 변환, 비어있으면 null (행사 기본값 사용)
    final depositRateText = _depositRateController.text.trim();
    final double? depositRate = depositRateText.isNotEmpty
        ? (double.tryParse(depositRateText) ?? 0) / 100
        : null;

    Map<String, dynamic> result;

    if (_isEditMode) {
      // 수정 모드: updateProduct API 호출
      result = await _productService.updateProduct(
        widget.product!['id'].toString(),
        {
          'name': name,
          'participationFee': fee,
          'commissionRate': commission / 100, // % → 소수
          'depositRate': depositRate, // null이면 행사 기본값
        },
      );
    } else {
      // 등록 모드: createProductByOrganizer API 호출
      result = await _productService.createProductByOrganizer(
        eventId: widget.eventId,
        name: name,
        participationFee: fee,
        commissionRate: commission / 100, // % → 소수 (예: 20 → 0.2)
        depositRate: depositRate,
      );
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditMode ? '품목이 수정되었습니다' : '품목이 등록되었습니다')),
      );
      Navigator.of(context).pop(true); // 성공 결과 전달
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '처리에 실패했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(title: _isEditMode ? '품목 수정하기' : '품목 추가하기'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "판매 품목 추가 >"
            const Row(
              children: [
                Text(
                  '판매 품목 추가',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20),
              ],
            ),
            const SizedBox(height: 24),

            // 품목명
            const Text('품목명', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textAlign: TextAlign.right,  // 오른쪽 정렬
              decoration: InputDecoration(
                hintText: '예시 : 줄눈 / 나노코팅 등',
                hintStyle: const TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // 참가비
            const Text('참가비', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _feeController,
              textAlign: TextAlign.right,  // 오른쪽 정렬
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CommaFormatter(),  // 천 단위 콤마 자동 삽입
              ],
              decoration: InputDecoration(
                suffixText: '원',
                suffixStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // 수수료
            const Text('수수료', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _commissionController,
              textAlign: TextAlign.right,  // 오른쪽 정렬
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: '%',
                suffixStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // 계약금 비율 (#10, #14 연계)
            const Text('계약금 비율', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              '비워두면 행사 기본값(30%) 사용',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _depositRateController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '예: 30',
                hintStyle: const TextStyle(color: AppColors.textHint),
                suffixText: '%',
                suffixStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      // 하단 "추가하기" 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: AppButton(
          text: _isSubmitting
              ? '처리 중...'
              : _isEditMode ? '수정하기' : '추가하기',
          onPressed: _isSubmitting ? null : _submit,
          backgroundColor: AppColors.organizer, // 주관사 주황색
        ),
      ),
    );
  }
}
