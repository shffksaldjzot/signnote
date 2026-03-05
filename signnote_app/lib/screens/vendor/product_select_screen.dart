import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/common/app_button.dart';
import '../../services/product_service.dart';
import '../../services/api_service.dart';

// ============================================
// 협력업체용 품목 선택 화면
//
// 업체가 참여코드로 행사에 입장한 직후 표시됨
// - "어떤 품목으로 참여하시겠습니까?"
// - 주관사가 등록한 품목 중 아직 선점되지 않은 것만 드롭다운으로 표시
// - 품목 선택 → "참여하기" 버튼 → 선점 완료
// - 남은 품목이 없으면 참여 불가 안내
// ============================================

class VendorProductSelectScreen extends StatefulWidget {
  final String eventId;    // 행사 ID
  final String eventTitle; // 행사명

  const VendorProductSelectScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<VendorProductSelectScreen> createState() =>
      _VendorProductSelectScreenState();
}

class _VendorProductSelectScreenState extends State<VendorProductSelectScreen> {
  List<Map<String, dynamic>> _availableProducts = []; // 선택 가능한 품목
  String? _selectedProductId; // 현재 선택한 품목 ID
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _loadAvailableProducts();
  }

  // 가용 품목 목록 불러오기
  Future<void> _loadAvailableProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _productService.getAvailableProducts(widget.eventId);

    if (!mounted) return;

    if (result['success'] == true) {
      final products = List<Map<String, dynamic>>.from(result['products'] ?? []);
      setState(() {
        _availableProducts = products;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? '품목을 불러올 수 없습니다';
        _isLoading = false;
      });
    }
  }

  // 품목 선점 처리
  Future<void> _claimProduct() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참여할 품목을 선택해 주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 사용자 정보에서 업체명 가져오기
    final userInfo = await ApiService().getUserInfo();
    final vendorName = userInfo?['name'] ?? '업체';

    final result = await _productService.claimProduct(
      productId: _selectedProductId!,
      vendorName: vendorName,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('품목 선택이 완료되었습니다!')),
      );
      Navigator.of(context).pop(true); // 성공 결과 전달
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '품목 선택에 실패했습니다')),
      );
      // 다른 업체가 먼저 선점했을 수 있으므로 목록 새로고침
      _loadAvailableProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(title: widget.eventTitle),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _availableProducts.isEmpty
                    ? _buildNoProducts()
                    : _buildProductSelector(),
      ),
    );
  }

  // 에러 표시
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadAvailableProducts, child: const Text('다시 시도')),
        ],
      ),
    );
  }

  // 남은 품목이 없을 때
  Widget _buildNoProducts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            '참여 가능한 품목이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '모든 품목이 다른 업체에 의해 선점되었습니다.\n주관사에 문의해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  // 품목 선택 드롭다운
  Widget _buildProductSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          '어떤 품목으로\n참여하시겠습니까?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_availableProducts.length}개 품목 선택 가능',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),

        // 품목 드롭다운
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProductId,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              hint: const Text(
                '품목을 선택해 주세요',
                style: TextStyle(color: AppColors.textHint),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              items: _availableProducts.map((product) {
                final fee = product['participationFee'] ?? 0;
                final feeText = fee > 0 ? ' (참가비: ${_formatPrice(fee)}원)' : '';
                return DropdownMenuItem(
                  value: product['id']?.toString(),
                  child: Text('${product['name']}$feeText'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedProductId = value);
              },
            ),
          ),
        ),

        const Spacer(),

        // 참여하기 버튼
        AppButton.black(
          text: _isSubmitting ? '처리 중...' : '참여하기',
          onPressed: _isSubmitting ? null : _claimProduct,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // 가격 포맷 (1,000 형태)
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
