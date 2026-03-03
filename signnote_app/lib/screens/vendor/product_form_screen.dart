import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/common/app_button.dart';

// ============================================
// 업체용 상품 추가/수정 폼 화면
//
// 디자인 참고: 9.업체용-품목 등록.jpg
// - 상단: ← "상품 추가" 또는 "상품 수정" 헤더
// - 입력 필드들:
//   - 카테고리 (줄눈, 나노코팅 등)
//   - 상품명
//   - 상품 설명 (여러 줄)
//   - 가격 (숫자만)
//   - 적용 타입 (체크박스: 74A, 74B, 84A, 84B)
//   - 상품 이미지 (나중에 업로드 기능 추가)
// - 하단: "등록하기" 또는 "수정하기" 버튼
// ============================================

class VendorProductFormScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic>? product;  // 수정 시 기존 데이터 (null이면 새 등록)

  const VendorProductFormScreen({
    super.key,
    required this.eventId,
    this.product,
  });

  @override
  State<VendorProductFormScreen> createState() => _VendorProductFormScreenState();
}

class _VendorProductFormScreenState extends State<VendorProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // 입력 필드 컨트롤러들
  late final TextEditingController _categoryController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  // 적용 타입 선택 (여러 개 선택 가능)
  late Set<String> _selectedTypes;
  bool _isLoading = false;

  // 수정 모드인지 여부
  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    // 수정 모드면 기존 데이터로 채우기
    _categoryController = TextEditingController(
      text: widget.product?['category'] ?? '',
    );
    _nameController = TextEditingController(
      text: widget.product?['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product?['description'] ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?['price']?.toString() ?? '',
    );
    _selectedTypes = Set<String>.from(
      widget.product?['housingTypes'] ?? ['84A'],
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // 폼 제출 (등록 또는 수정)
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('적용 타입을 1개 이상 선택해 주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: API 호출로 실제 등록/수정 처리
    // 현재는 성공했다고 가정하고 이전 화면으로 돌아감
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? '상품이 수정되었습니다' : '상품이 등록되었습니다'),
        ),
      );
      Navigator.of(context).pop(true);  // true = 변경됨 (목록 새로고침용)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(title: _isEditMode ? '상품 수정' : '상품 추가'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 입력
              _buildLabel('카테고리'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _categoryController,
                hint: '예: 줄눈, 나노코팅, 에어컨',
                validator: (v) => v == null || v.isEmpty ? '카테고리를 입력해 주세요' : null,
              ),
              const SizedBox(height: 20),

              // 상품명 입력
              _buildLabel('상품명'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: '예: 줄눈 A 패키지',
                validator: (v) => v == null || v.isEmpty ? '상품명을 입력해 주세요' : null,
              ),
              const SizedBox(height: 20),

              // 상품 설명 입력
              _buildLabel('상품 설명'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: '예: 욕실2바닥+현관+안방샤워부스 벽면1곳',
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // 가격 입력
              _buildLabel('가격 (원)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _priceController,
                hint: '예: 700000',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return '가격을 입력해 주세요';
                  if (int.tryParse(v) == null) return '올바른 숫자를 입력해 주세요';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 적용 타입 선택 (체크박스)
              _buildLabel('적용 타입'),
              const SizedBox(height: 8),
              _buildTypeCheckboxes(),
              const SizedBox(height: 20),

              // 상품 이미지 (나중에 업로드 기능 추가)
              _buildLabel('상품 이미지'),
              const SizedBox(height: 8),
              _buildImagePlaceholder(),
              const SizedBox(height: 32),

              // 등록/수정 버튼
              AppButton.black(
                text: _isEditMode ? '수정하기' : '등록하기',
                isLoading: _isLoading,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 라벨 텍스트
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  // 공통 텍스트 입력 필드
  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.priceRed),
        ),
      ),
    );
  }

  // 타입 체크박스 (여러 개 선택 가능)
  Widget _buildTypeCheckboxes() {
    return Wrap(
      spacing: 8,
      children: AppConstants.defaultHousingTypes.map((type) {
        final isSelected = _selectedTypes.contains(type);
        return FilterChip(
          label: Text('$type타입'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTypes.add(type);
              } else {
                _selectedTypes.remove(type);
              }
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
        );
      }).toList(),
    );
  }

  // 이미지 업로드 영역 (나중에 구현)
  Widget _buildImagePlaceholder() {
    return GestureDetector(
      onTap: () {
        // TODO: 이미지 선택 기능 구현
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 업로드 기능은 추후 추가됩니다')),
        );
      },
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textHint),
            SizedBox(height: 8),
            Text(
              '이미지 추가',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
