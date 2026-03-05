import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/common/app_button.dart';
import '../../services/product_service.dart';

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

  const OrganizerProductAddScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<OrganizerProductAddScreen> createState() =>
      _OrganizerProductAddScreenState();
}

class _OrganizerProductAddScreenState extends State<OrganizerProductAddScreen> {
  final _nameController = TextEditingController();         // 품목명
  final _feeController = TextEditingController();          // 참가비
  final _commissionController = TextEditingController();   // 수수료
  String? _imageBase64;   // 품목 설명 이미지 (base64)
  bool _isSubmitting = false;

  final ProductService _productService = ProductService();

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  // 이미지 선택 (갤러리에서)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    }
  }

  // 품목 등록 API 호출
  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('품목명을 입력해 주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final fee = int.tryParse(_feeController.text.trim()) ?? 0;
    final commission = double.tryParse(_commissionController.text.trim()) ?? 0;

    final result = await _productService.createProductByOrganizer(
      eventId: widget.eventId,
      name: name,
      participationFee: fee,
      commissionRate: commission / 100, // % → 소수 (예: 20 → 0.2)
      image: _imageBase64,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('품목이 등록되었습니다')),
      );
      Navigator.of(context).pop(true); // 성공 결과 전달
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '등록에 실패했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppHeader(title: '품목 추가하기'),
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
              keyboardType: TextInputType.number,
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

            // 품목 설명 이미지
            const Text('품목 설명 이미지', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(_imageBase64!.split(',').last),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      // 하단 "추가하기" 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: AppButton(
          text: _isSubmitting ? '등록 중...' : '추가하기',
          onPressed: _isSubmitting ? null : _submit,
        ),
      ),
    );
  }
}
