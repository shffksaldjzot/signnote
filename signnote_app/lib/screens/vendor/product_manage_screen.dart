import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/product/housing_type_selector.dart';
import '../../widgets/common/app_button.dart';
import 'product_form_screen.dart';

// ============================================
// 업체용 품목 관리 화면
//
// 디자인 참고: 8.업체용-품목 관리.jpg
// - 상단: ← 행사명 헤더
// - "내 품목 리스트 >" + 타입 뱃지
// - 카테고리별 내 상품 목록
// - 상품 카드에 수정(연필) 아이콘
// - 하단: "상품 추가" 버튼 + 3탭 네비게이션
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
  int _currentTabIndex = 0;
  final String _selectedType = '84A';

  // TODO: API에서 내 상품 목록 가져오기 (현재 임시 데이터)
  final List<Map<String, dynamic>> _myProducts = [
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
  ];

  // 카테고리별로 상품 그룹핑
  Map<String, List<Map<String, dynamic>>> get _groupedProducts {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final product in _myProducts) {
      final category = product['category'] as String;
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(product);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(title: widget.eventTitle),
      body: Column(
        children: [
          // "내 품목 리스트 >" + 타입 뱃지
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      '내 품목 리스트',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                // 타입 뱃지
                HousingTypeBadge(type: _selectedType),
              ],
            ),
          ),
          // 상품 목록 (카테고리별)
          Expanded(
            child: _myProducts.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: _groupedProducts.entries.map((entry) {
                      final category = entry.key;
                      final products = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          // 카테고리 헤더
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          // 카테고리 내 상품들 (수정 아이콘 표시)
                          ...products.map((product) => ProductCard(
                            vendorName: product['vendorName'],
                            productName: product['name'],
                            description: product['description'],
                            price: product['price'],
                            imageUrl: product['imageUrl'],
                            onEditTap: () {
                              // 상품 수정 화면으로 이동
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => VendorProductFormScreen(
                                    eventId: widget.eventId,
                                    product: product,  // 기존 상품 데이터 전달
                                  ),
                                ),
                              );
                            },
                          )),
                          const Divider(height: 24),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      // 하단: "상품 추가" 버튼 + 탭바
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: AppButton.black(
              text: '상품 추가',
              onPressed: () {
                // 상품 추가 화면으로 이동 (빈 폼)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VendorProductFormScreen(
                      eventId: widget.eventId,
                    ),
                  ),
                );
              },
            ),
          ),
          AppTabBar.vendor(
            currentIndex: _currentTabIndex,
            onTap: (index) => setState(() => _currentTabIndex = index),
          ),
        ],
      ),
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
            '등록된 상품이 없습니다',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          SizedBox(height: 4),
          Text(
            '아래 버튼을 눌러 상품을 추가해 보세요',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
