import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/product/housing_type_selector.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_modal.dart';
import '../../widgets/common/empty_state.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import 'cart_screen.dart';

// ============================================
// 행사 상세 화면 (구매 품목 리스트)
//
// 디자인 참고: 5.고객용-행사 상세.jpg, 6.고객용-품목 상세.jpg
// - 상단: ← 행사명 헤더 + 타입 뱃지(84A타입)
// - "구매 품목 리스트 >"
// - 카테고리별 상품 목록 (서버에서 불러옴)
// - 상품 카드: 이미지 + 업체명 + 상품명 + 설명 + 가격 + 장바구니(+)
// - 하단: 플로팅 "장바구니" 버튼 + 4탭 네비게이션
// ============================================

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int _currentTabIndex = 0;
  String _selectedType = '84A'; // 현재 선택된 평형 타입
  final Set<String> _cartProductIds = {}; // 장바구니에 담긴 상품 ID들

  // 서버에서 불러온 상품 목록
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;

  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // 서버에서 상품 목록 불러오기
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _productService.getProductsByEvent(
      widget.eventId,
      housingType: _selectedType,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final products = List<Map<String, dynamic>>.from(result['products'] ?? []);
      setState(() {
        _products = products.map((p) {
          return {
            'id': p['id']?.toString() ?? '',
            'category': p['category'] ?? '기타',
            'vendorName': p['vendorName'] ?? '업체명 없음',
            'name': p['name'] ?? '상품명 없음',
            'description': p['description'] ?? '',
            'price': p['price'] ?? 0,
            'imageUrl': p['image'],
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

  // 카테고리별로 상품 그룹핑
  Map<String, List<Map<String, dynamic>>> get _groupedProducts {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final product in _products) {
      final category = product['category'] as String;
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(product);
    }
    return grouped;
  }

  // 장바구니에 추가/제거 (서버 연동)
  Future<void> _toggleCart(String productId) async {
    setState(() {
      if (_cartProductIds.contains(productId)) {
        _cartProductIds.remove(productId);
      } else {
        _cartProductIds.add(productId);
      }
    });

    // 서버에 장바구니 추가
    if (_cartProductIds.contains(productId)) {
      await _cartService.addItem(
        productId: productId,
        eventId: widget.eventId,
      );
    }
  }

  // 품목 상세 바텀시트 표시
  void _showProductDetail(Map<String, dynamic> product) {
    AppModal.showBottomSheet(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리명
          Text(
            product['category'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // 상품 이미지 영역
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: product['imageUrl'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(product['imageUrl'], fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(Icons.image_outlined, size: 48, color: AppColors.textHint),
                  ),
          ),
          const SizedBox(height: 16),
          // 업체명
          Text(
            product['vendorName'],
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          // 상품명
          Text(
            product['name'],
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          // 설명
          Text(
            product['description'] ?? '',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          // 가격
          RichText(
            text: TextSpan(children: [
              const TextSpan(
                text: '가격 : ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
              TextSpan(
                text: '${_formatPrice(product['price'])}원',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.priceRed),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          // 장바구니 담기 버튼
          AppButton(
            text: '장바구니 담기',
            onPressed: () {
              _toggleCart(product['id']);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(title: widget.eventTitle),
      body: Column(
        children: [
          // "구매 품목 리스트 >" + 타입 뱃지
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      '구매 품목 리스트',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                // 타입 뱃지 (누르면 타입 선택 모달)
                GestureDetector(
                  onTap: () => _showTypeSelector(),
                  child: HousingTypeBadge(type: _selectedType),
                ),
              ],
            ),
          ),
          // 상품 목록 (로딩/에러/데이터 분기)
          Expanded(child: _buildProductList()),
        ],
      ),
      // 플로팅 장바구니 버튼
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_cartProductIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: AppButton(
                text: '장바구니',
                badgeCount: _cartProductIds.length,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CartScreen(
                        eventId: widget.eventId,
                        eventTitle: widget.eventTitle,
                      ),
                    ),
                  );
                },
              ),
            ),
          AppTabBar.customer(
            currentIndex: _currentTabIndex,
            onTap: (index) => setState(() => _currentTabIndex = index),
          ),
        ],
      ),
    );
  }

  // 상품 목록 (로딩/에러/비어있음/데이터)
  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        message: _error!,
        actionLabel: '다시 시도',
        onAction: _loadProducts,
      );
    }
    if (_products.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        message: '등록된 품목이 없습니다',
        subMessage: '아직 업체에서 품목을 등록하지 않았습니다',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: _groupedProducts.entries.map((entry) {
        final category = entry.key;
        final products = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // 카테고리 헤더
            Row(
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.help_outline, size: 16, color: AppColors.textSecondary),
              ],
            ),
            // 카테고리 내 상품들
            ...products.map((product) => ProductCard(
              vendorName: product['vendorName'],
              productName: product['name'],
              description: product['description'],
              price: product['price'],
              imageUrl: product['imageUrl'],
              isInCart: _cartProductIds.contains(product['id']),
              onDetailTap: () => _showProductDetail(product),
              onAddToCart: () => _toggleCart(product['id']),
            )),
            const Divider(height: 24),
          ],
        );
      }).toList(),
    );
  }

  // 타입 선택 모달
  void _showTypeSelector() {
    AppModal.show(
      context,
      title: '타입을 선택해 주세요.',
      child: Column(
        children: [
          HousingTypeRadio(
            types: const ['74A', '74B', '84A', '84B'],
            selectedType: _selectedType,
            onSelected: (type) {
              setState(() => _selectedType = type);
              Navigator.of(context).pop();
              _loadProducts(); // 타입 변경 시 상품 다시 불러오기
            },
          ),
          const SizedBox(height: 16),
          AppButton(
            text: '완료',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
