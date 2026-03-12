import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/layout/app_header.dart';
import '../../services/product_service.dart';
import '../../services/event_service.dart';
import '../../utils/number_formatter.dart';
import '../../utils/image_helper.dart';
import '../common/image_gallery_screen.dart';

// ============================================
// 업체용 상세 품목(2뎁스) 추가/수정 폼 화면
//
// 디자인 참고: 4.업체용-품목 추가하기.jpg
// - 품목(1뎁스) 드롭다운: 배정받은 품목에서 선택
// - 품목 제목 (패키지명)
// - 적용 타입 (칩)
// - 상세 품목 (설명)
// - 비용 (원)
// - 품목 이미지 (카메라/갤러리에서 선택)
// - 하단: "작성 완료" 버튼
// ============================================

class VendorProductFormScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic>? product;      // 수정 시: 상세 품목(2뎁스) 데이터
  final String? preSelectedProductId;        // 미리 선택된 1뎁스 품목 ID

  const VendorProductFormScreen({
    super.key,
    required this.eventId,
    this.product,
    this.preSelectedProductId,
  });

  @override
  State<VendorProductFormScreen> createState() => _VendorProductFormScreenState();
}

class _VendorProductFormScreenState extends State<VendorProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final EventService _eventService = EventService();
  final ImagePicker _imagePicker = ImagePicker();

  // 입력 필드 컨트롤러
  late final TextEditingController _nameController;       // 패키지명
  late final TextEditingController _descriptionController; // 상세 설명
  late final TextEditingController _priceController;       // 비용

  // 배정받은 1뎁스 품목 목록 (드롭다운용)
  List<Map<String, dynamic>> _assignedProducts = [];
  String? _selectedProductId;  // 선택된 1뎁스 품목 ID

  // 적용 타입
  late Set<String> _selectedTypes;
  List<String> _eventHousingTypes = [];

  // 이미지 목록 (base64 데이터 URL, 최대 5장)
  final List<String> _images = [];
  static const int _maxImages = 5;

  bool _isLoading = false;
  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    _loadData();

    // 수정 모드면 기존 데이터로 채우기
    _selectedProductId = widget.product?['productId'] ?? widget.preSelectedProductId;
    _nameController = TextEditingController(text: widget.product?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.product?['description'] ?? '');
    _priceController = TextEditingController(
      text: widget.product?['price'] != null ? formatWithComma(widget.product!['price'] as int) : '',
    );
    _selectedTypes = Set<String>.from(widget.product?['housingTypes'] ?? []);

    // 기존 이미지 로드 (수정 모드)
    if (widget.product != null) {
      final existingImages = widget.product!['images'];
      if (existingImages is List && existingImages.isNotEmpty) {
        _images.addAll(List<String>.from(existingImages));
      } else {
        // images 배열이 없으면 단일 image 필드에서 가져오기
        final singleImage = widget.product!['image'] ?? widget.product!['imageUrl'];
        if (singleImage != null && singleImage.toString().isNotEmpty) {
          _images.add(singleImage.toString());
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // 행사 데이터 + 배정받은 품목 가져오기
  Future<void> _loadData() async {
    // 행사 상세에서 타입 목록 가져오기
    final eventResult = await _eventService.getEventDetail(widget.eventId);
    if (!mounted) return;

    if (eventResult['success'] == true) {
      final event = eventResult['event'] as Map<String, dynamic>? ?? {};
      final types = event['housingTypes'];
      if (types is List && types.isNotEmpty) {
        setState(() {
          _eventHousingTypes = List<String>.from(types);
        });
      }
    }

    // 타입 기본값
    if (_eventHousingTypes.isEmpty) {
      setState(() {
        _eventHousingTypes = List<String>.from(AppConstants.defaultHousingTypes);
      });
    }

    // 배정받은 1뎁스 품목 목록 (내 품목)
    final myResult = await _productService.getMyProducts(eventId: widget.eventId);
    if (!mounted) return;

    if (myResult['success'] == true) {
      final List products = myResult['products'] ?? [];
      setState(() {
        _assignedProducts = products.map<Map<String, dynamic>>((p) => {
          'id': p['id']?.toString() ?? '',
          'name': p['name'] ?? '',
          'category': p['category'] ?? '',
        }).toList();
      });
    }
  }

  // 폼 제출
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null || _selectedProductId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('품목을 선택해 주세요')),
      );
      return;
    }
    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('적용 타입을 1개 이상 선택해 주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    if (_isEditMode) {
      // 수정: ProductItem 수정 API (이미지 포함)
      result = await _productService.updateProductItem(
        widget.product!['id'].toString(),
        {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': parseCommaNumber(_priceController.text),
          'housingTypes': _selectedTypes.toList(),
          'images': _images,
          if (_images.isNotEmpty) 'image': _images.first, // 대표 이미지 (하위호환)
        },
      );
    } else {
      // 생성: ProductItem 생성 API (이미지 포함)
      result = await _productService.createProductItem(
        productId: _selectedProductId!,
        name: _nameController.text,
        housingTypes: _selectedTypes.toList(),
        price: parseCommaNumber(_priceController.text),
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        image: _images.isNotEmpty ? _images.first : null, // 대표 이미지 (하위호환)
        images: _images.isNotEmpty ? _images : null,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditMode ? '품목이 수정되었습니다' : '품목이 등록되었습니다')),
      );
      Navigator.of(context).pop(true);
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
      appBar: AppHeader(title: _isEditMode ? '품목 수정' : '품목 추가하기'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "판매 품목 추가 >"
              const Row(
                children: [
                  Text('판매 품목 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 20),
                ],
              ),
              const SizedBox(height: 20),

              // 품목 드롭다운 (배정받은 1뎁스 품목에서 선택)
              _buildProductDropdown(),
              const SizedBox(height: 20),

              // 품목 제목 (패키지명)
              _buildLabel('품목 제목'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: '예시 : 기본 패키지 / A 패키지',
                validator: (v) => v == null || v.isEmpty ? '품목 제목을 입력해 주세요' : null,
              ),
              const SizedBox(height: 20),

              // 적용 타입
              _buildLabel('적용 타입'),
              const SizedBox(height: 8),
              _buildTypeChips(),
              const SizedBox(height: 20),

              // 상세 품목
              _buildLabel('상세 품목'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: '상세 품목을 작성해 주세요.',
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // 비용
              _buildLabel('비용'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _priceController,
                hint: '',
                keyboardType: TextInputType.number,
                suffixText: '원',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CommaFormatter(),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return '비용을 입력해 주세요';
                  if (parseCommaNumber(v) <= 0) return '올바른 금액을 입력해 주세요';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 품목 이미지 (최대 5장)
              _buildLabel('품목 이미지'),
              const SizedBox(height: 4),
              Text(
                '최대 $_maxImages장까지 등록 가능합니다',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const SizedBox(height: 8),
              _buildImagePicker(),
              const SizedBox(height: 32),

              // "작성 완료" 검정 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vendor,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : Text(_isEditMode ? '수정 완료' : '작성 완료'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 품목 드롭다운 (배정받은 1뎁스 품목)
  Widget _buildProductDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedProductId != null &&
                  _assignedProducts.any((p) => p['id'] == _selectedProductId)
              ? _selectedProductId
              : null,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          items: [
            // 첫 번째 줄: 미선택 상태
            const DropdownMenuItem<String?>(value: null, child: Text('품목 선택', style: TextStyle(fontSize: 14, color: AppColors.textHint))),
            ..._assignedProducts.map((product) {
              return DropdownMenuItem<String?>(
                value: product['id'],
                child: Text(product['name'], style: const TextStyle(fontSize: 14)),
              );
            }),
          ],
          onChanged: _isEditMode ? null : (value) {
            setState(() => _selectedProductId = value);
          },
        ),
      ),
    );
  }

  // 적용 타입 칩
  Widget _buildTypeChips() {
    if (_eventHousingTypes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Wrap(
      spacing: 8,
      children: _eventHousingTypes.map((type) {
        final isSelected = _selectedTypes.contains(type);
        return FilterChip(
          label: Text(type),
          selected: isSelected,
          showCheckmark: false, // V자 대신 색상만 변경
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // 선택 시 크기 변동 방지
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTypes.add(type);
              } else {
                _selectedTypes.remove(type);
              }
            });
          },
          selectedColor: AppColors.vendor, // 선택 시 진한 검정 배경
          labelStyle: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textSecondary, // 선택 시 흰 글씨
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? AppColors.vendor : AppColors.border),
          ),
        );
      }).toList(),
    );
  }

  // 라벨
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );
  }

  // 텍스트 입력 필드
  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? suffixText,
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
        suffixText: suffixText,
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
          borderSide: const BorderSide(color: AppColors.vendor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.priceRed),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 이미지 업로드 UI (최대 5장)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // 이미지 피커 UI — 가로 스크롤, 추가 버튼 + 이미지 썸네일들
  Widget _buildImagePicker() {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "+" 추가 버튼 (5장 미만일 때만 표시)
          if (_images.length < _maxImages)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.background,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, color: AppColors.textHint, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '${_images.length}/$_maxImages',
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ),
          // 이미지 썸네일 목록
          ..._images.asMap().entries.map((entry) {
            final idx = entry.key;
            final imageUrl = entry.value;
            return GestureDetector(
              onTap: () => _openGallery(idx),
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    // 이미지 썸네일
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: buildSmartImage(imageUrl, width: 80, height: 80),
                      ),
                    ),
                    // 대표 이미지 뱃지 (첫번째 이미지)
                    if (idx == 0)
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.vendor,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(6),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '대표',
                            style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    // 삭제 버튼 (우상단 X)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: GestureDetector(
                        onTap: () => _removeImage(idx),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 갤러리에서 이미지 선택 → base64로 변환 후 목록에 추가
  Future<void> _pickImage() async {
    if (_images.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지는 최대 $_maxImages장까지 등록 가능합니다')),
      );
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 70,
    );
    if (picked == null) return;

    // base64 데이터 URL로 변환
    final bytes = await picked.readAsBytes();
    final base64String = base64Encode(bytes);
    final mimeType = picked.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    final dataUrl = 'data:$mimeType;base64,$base64String';

    setState(() => _images.add(dataUrl));
  }

  // 이미지 삭제
  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  // 이미지 갤러리 뷰어 열기 (전체화면)
  void _openGallery(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageGalleryScreen(
          images: _images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}
