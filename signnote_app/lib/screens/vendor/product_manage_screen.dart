import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/common/app_button.dart';
import '../../services/product_service.dart';
import '../../utils/image_helper.dart';
import 'product_form_screen.dart';
import 'contract_screen.dart';

// ============================================
// 업체용 품목 관리 화면
//
// 디자인 참고: 3.업체용-품목 상세.jpg
// - 상단: ← 행사명 헤더
// - "판매 품목 리스트 >"
// - 업체 자신의 상세 품목만 표시
// - 처음엔 빈 상태 + "품목 추가하기" 버튼
// - 하단: 3탭 네비게이션 (홈/계약함/마이페이지)
// ============================================

class VendorProductManageScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const VendorProductManageScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<VendorProductManageScreen> createState() =>
      _VendorProductManageScreenState();
}

class _VendorProductManageScreenState extends State<VendorProductManageScreen> {
  final int _currentTabIndex = 0;

  // API에서 가져온 내 상세 품목 목록
  List<Map<String, dynamic>> _myProducts = [];
  bool _isLoading = true;
  String? _error;

  final ProductService _productService = ProductService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProducts(); // 화면 열릴 때 내 상품 목록 불러오기
  }

  // 서버에서 내 상품 목록 가져오기 (업체 자신의 상세 품목만)
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _productService.getMyProducts(eventId: widget.eventId);

    if (!mounted) return;

    if (result['success'] == true) {
      final List products = result['products'] ?? [];
      setState(() {
        _myProducts = products.map<Map<String, dynamic>>((p) {
          return {
            'id': p['id']?.toString() ?? '',
            'category': p['category'] ?? '기타',
            'vendorName': p['vendorName'] ?? '',
            'name': p['name'] ?? '상품명 없음',
            'description': p['description'] ?? '',
            'price': p['price'] ?? 0,
            'imageUrl': p['image'],
            'image': p['image'],
            'images': p['images'] != null ? List<String>.from(p['images']) : <String>[],
            'housingTypes': p['housingTypes'] != null
                ? List<String>.from(p['housingTypes'])
                : <String>[],
          };
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? '상품 목록을 불러올 수 없습니다';
        _isLoading = false;
      });
    }
  }

  // 갤러리에서 이미지 선택 → 서버에 업데이트
  Future<void> _pickAndUploadImage(Map<String, dynamic> product) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 70,
    );
    if (picked == null) return;

    // base64로 변환
    final bytes = await picked.readAsBytes();
    final base64String = base64Encode(bytes);
    final mimeType = picked.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    final dataUrl = 'data:$mimeType;base64,$base64String';

    // 서버에 이미지 업데이트
    final result = await _productService.updateProductItem(
      product['id'].toString(),
      {'image': dataUrl},
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지가 업데이트되었습니다')),
      );
      _loadProducts(); // 목록 새로고침
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '이미지 업로드에 실패했습니다')),
      );
    }
  }

  // 탭 클릭 시 화면 이동
  void _onTabChanged(int index) {
    if (index == _currentTabIndex) return;
    switch (index) {
      case 0: // 홈 → 업체 홈으로 돌아가기
        Navigator.of(context).pop();
        break;
      case 1: // 계약함
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VendorContractScreen()),
        );
        break;
      case 2: // 마이페이지
        context.push(AppRoutes.mypage, extra: 'VENDOR');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(title: widget.eventTitle),
      body: Column(
        children: [
          // "판매 품목 리스트 >"
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                const Text(
                  '판매 품목 리스트',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
          // 상품 목록
          Expanded(child: _buildBody()),
        ],
      ),
      // 하단: "품목 추가하기" 버튼 + 탭바
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: AppButton.black(
              text: '품목 추가하기',
              onPressed: () async {
                // 상세 품목 추가 화면으로 이동
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => VendorProductFormScreen(
                      eventId: widget.eventId,
                    ),
                  ),
                );
                // 추가 성공 시 목록 새로고침
                if (result == true) _loadProducts();
              },
            ),
          ),
          AppTabBar.vendor(
            currentIndex: _currentTabIndex,
            onTap: _onTabChanged,
          ),
        ],
      ),
    );
  }

  // 본문: 로딩 / 에러 / 상품 목록 분기
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadProducts, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_myProducts.isEmpty) return _buildEmptyState();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: _myProducts.map((product) {
        final formattedPrice = NumberFormat('#,###').format(product['price']);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽: 썸네일 이미지 (탭하면 갤러리에서 이미지 선택/변경)
              GestureDetector(
                onTap: () => _pickAndUploadImage(product),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: AppColors.background,
                    child: (product['imageUrl'] != null && (product['imageUrl'] as String).isNotEmpty)
                        ? buildSmartImage(
                            product['imageUrl'] as String?,
                            width: 80,
                            height: 80,
                          )
                        // 이미지 미등록: 회백 배경에 + 표시
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColors.textHint),
                              SizedBox(height: 2),
                              Text('이미지 추가', style: TextStyle(fontSize: 9, color: AppColors.textHint)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 오른쪽: 상품 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 업체명
                    if (product['vendorName'] != null && (product['vendorName'] as String).isNotEmpty)
                      Text(
                        product['vendorName'],
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    const SizedBox(height: 2),
                    // 상품명
                    Text(
                      product['name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    // 설명
                    if (product['description'] != null && (product['description'] as String).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product['description'],
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    // 가격 + 수정 아이콘
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: '가격 : ',
                                style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                              ),
                              TextSpan(
                                text: '$formattedPrice원',
                                style: const TextStyle(fontSize: 14, color: AppColors.priceRed, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            // 상품 수정 화면으로 이동
                            final result = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => VendorProductFormScreen(
                                  eventId: widget.eventId,
                                  product: product,
                                ),
                              ),
                            );
                            if (result == true) _loadProducts();
                          },
                          child: Image.asset('assets/icons/vendor/write.png', width: 20, height: 20, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 상품이 없을 때 표시
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            '등록된 상세 품목이 없습니다',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          SizedBox(height: 4),
          Text(
            '아래 버튼을 눌러 상세 품목을 추가해 보세요',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
