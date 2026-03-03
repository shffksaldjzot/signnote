import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/product/housing_type_selector.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_modal.dart';
import 'cart_screen.dart';

// ============================================
// 행사 상세 화면 (구매 품목 리스트)
//
// 디자인 참고: 5.고객용-행사 상세.jpg, 6.고객용-품목 상세.jpg
// - 상단: ← 행사명 헤더 + 타입 뱃지(84A타입)
// - "구매 품목 리스트 >"
// - 카테고리별 상품 목록 (줄눈, 나노코팅 등)
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
  String _selectedType = '84A';   // 현재 선택된 평형 타입
  final Set<String> _cartProductIds = {};  // 장바구니에 담긴 상품 ID들

  // TODO: API에서 상품 목록 가져오기 (현재 임시 데이터)
  final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'category': '줄눈',
      'vendorName': '앤드 디자인',
      'name': '줄눈 A 패키지',
      'description': '욕실2바닥+현관+안방샤워부스 벽면1곳\n+다용도실',
      'price': 700000,
      'imageUrl': null,
    },
    {
      'id': '2',
      'category': '줄눈',
      'vendorName': '앤드 디자인',
      'name': '줄눈 B 패키지',
      'description': 'A패키지 + 욕실 전체벽',
      'price': 1400000,
      'imageUrl': null,
    },
    {
      'id': '3',
      'category': '나노코팅',
      'vendorName': '워터바이',
      'name': '나노코팅 A 패키지',
      'description': '(욕실)거울2+세면대2+변기2+샤워부스1\n(주방)싱크대 상판',
      'price': 700000,
      'imageUrl': null,
    },
  ];

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

  // 장바구니에 추가/제거
  void _toggleCart(String productId) {
    setState(() {
      if (_cartProductIds.contains(productId)) {
        _cartProductIds.remove(productId);
      } else {
        _cartProductIds.add(productId);
      }
    });
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
            child: const Center(
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
          // 가격 (빨간색)
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
                Row(
                  children: [
                    const Text(
                      '구매 품목 리스트',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
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
          // 상품 목록 (카테고리별)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: _groupedProducts.entries.map((entry) {
                final category = entry.key;
                final products = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // 카테고리 헤더 (줄눈 ?)
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
            ),
          ),
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
                  // 장바구니 화면으로 이동
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
