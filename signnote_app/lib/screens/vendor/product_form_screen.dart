import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/common/app_button.dart';
import '../../services/product_service.dart';
import '../../services/event_service.dart';
import '../../utils/number_formatter.dart';

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
  final ProductService _productService = ProductService();

  // 입력 필드 컨트롤러들
  late final TextEditingController _categoryController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  // 적용 타입 선택 (여러 개 선택 가능)
  late Set<String> _selectedTypes;
  // 행사에서 설정된 타입 목록 (서버에서 가져옴)
  List<String> _eventHousingTypes = [];
  bool _isLoading = false;

  // 수정 모드인지 여부
  bool get _isEditMode => widget.product != null;

  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _loadEventTypes(); // 행사별 타입 목록 가져오기
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
      text: widget.product?['price'] != null
          ? formatWithComma(widget.product!['price'] as int)
          : '',
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

  // 행사에서 설정된 타입 목록 가져오기
  Future<void> _loadEventTypes() async {
    final result = await _eventService.getEventDetail(widget.eventId);
    if (!mounted) return;
    if (result['success'] == true) {
      final event = result['event'] as Map<String, dynamic>? ?? {};
      final types = event['housingTypes'];
      if (types is List && types.isNotEmpty) {
        setState(() {
          _eventHousingTypes = List<String>.from(types);
        });
      }
    }
    // 서버에서 못 가져오면 기본 타입 사용
    if (_eventHousingTypes.isEmpty) {
      setState(() {
        _eventHousingTypes = List<String>.from(AppConstants.defaultHousingTypes);
      });
    }
  }

  // 폼 제출 (등록 또는 수정) — 실제 API 호출
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('적용 타입을 1개 이상 선택해 주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    if (_isEditMode) {
      // 수정 모드: updateProduct API 호출
      result = await _productService.updateProduct(
        widget.product!['id'].toString(),
        {
          'category': _categoryController.text,
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': parseCommaNumber(_priceController.text),
          'housingTypes': _selectedTypes.toList(),
        },
      );
    } else {
      // 등록 모드: createProduct API 호출
      result = await _productService.createProduct(
        eventId: widget.eventId,
        name: _nameController.text,
        category: _categoryController.text,
        vendorName: '', // 서버에서 로그인 사용자 정보로 자동 처리
        housingTypes: _selectedTypes.toList(),
        price: parseCommaNumber(_priceController.text),
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? '상품이 수정되었습니다' : '상품이 등록되었습니다'),
        ),
      );
      Navigator.of(context).pop(true);  // true = 변경됨 (목록 새로고침용)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? '처리에 실패했습니다'),
        ),
      );
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
                hint: '예: 700,000',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CommaFormatter(),  // 천 단위 콤마 자동 삽입
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return '가격을 입력해 주세요';
                  if (parseCommaNumber(v) <= 0) return '올바른 숫자를 입력해 주세요';
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
    if (_eventHousingTypes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Wrap(
      spacing: 8,
      children: _eventHousingTypes.map((type) {
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
        // 이미지 선택 (파일 스토리지 연동 시 활성화)
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
