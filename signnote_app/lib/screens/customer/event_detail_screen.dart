import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../services/event_service.dart';
import '../../utils/image_helper.dart';
import 'cart_screen.dart';
import 'contract_screen.dart';
import '../common/mypage_screen.dart';

// ============================================
// 행사 상세 화면 (구매 품목 리스트 — 2뎁스 구조)
//
// 디자인 참고: 5.고객용-행사 상세.jpg, 6.고객용-품목 상세.jpg
// - 상단: 행사명 + 내 타입 뱃지
// - "구매 품목 리스트 >" 제목
// - 1뎁스 품목별 아코디언 (줄눈, 나노코팅 등)
//   - 접힌 상태에서도 기본 1개 상세 품목 노출
//   - 펼치면 모든 2뎁스 상세 품목(패키지) 표시
// - 각 패키지: 이미지 + 업체명 + 패키지명 + 설명 + 가격 + 장바구니 버튼
// - 장바구니 담긴 품목은 파란 V 체크 표시
// - 하단: "장바구니" 버튼 + 담긴 수량 뱃지
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
  String? _myHousingType; // 내 평형 타입

  // 서버에서 불러온 1뎁스 품목 목록 (각각 items: 2뎁스 배열 포함)
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;

  // 장바구니에 담긴 productItemId 집합
  final Set<String> _cartItemIds = {};
  // productItemId → cartItemId 매핑 (삭제용)
  final Map<String, String> _cartItemIdMap = {};

  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  final EventService _eventService = EventService();
  final _priceFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _initData(); // 내 정보 먼저 가져온 후 품목 로드 (타입 필터링 적용)
    _loadCartItems();
  }

  // 내 정보 → 품목 로드 순서 보장 (타입 필터링 위해)
  Future<void> _initData() async {
    await _loadMyInfo();
    _loadProducts();
  }

  // 내 평형 정보 가져오기
  Future<void> _loadMyInfo() async {
    final result = await _eventService.getMyParticipantInfo(widget.eventId);
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _myHousingType = data['housingType']?.toString();
      });
    }
  }

  // 서버에서 품목 목록 불러오기 (1뎁스 + 2뎁스 items 포함)
  Future<void> _loadProducts() async {
    setState(() { _isLoading = true; _error = null; });

    final result = await _productService.getProductsByEvent(
      widget.eventId,
      housingType: _myHousingType,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final products = List<Map<String, dynamic>>.from(result['products'] ?? []);
      setState(() {
        _products = products.map((p) {
          // 2뎁스 상세 품목 목록 파싱
          final items = (p['items'] as List?)?.map<Map<String, dynamic>>((item) => {
            'id': item['id']?.toString() ?? '',
            'productId': p['id']?.toString() ?? '',
            'name': item['name'] ?? '패키지명 없음',
            'description': item['description'] ?? '',
            'price': item['price'] ?? 0,
            'imageUrl': item['image'],
            'housingTypes': item['housingTypes'] != null ? List<String>.from(item['housingTypes']) : <String>[],
            'vendorName': p['vendorName'] ?? '업체명 없음',
            'category': p['category'] ?? p['name'] ?? '기타',
          }).toList() ?? [];

          return {
            'id': p['id']?.toString() ?? '',
            'category': p['category'] ?? '기타',
            'name': p['name'] ?? '품목명 없음',
            'vendorName': p['vendorName'] ?? '업체명 없음',
            'items': items,
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

  // 장바구니 목록 불러와서 이미 담긴 항목 체크
  Future<void> _loadCartItems() async {
    final result = await _cartService.getCartItems(eventId: widget.eventId);
    if (!mounted) return;
    if (result['success'] == true) {
      final items = List<Map<String, dynamic>>.from(result['items'] ?? []);
      setState(() {
        _cartItemIds.clear();
        _cartItemIdMap.clear();
        for (final item in items) {
          // productItemId(2뎁스)를 우선 사용 — v체크 매칭에 사용
          final productItemId = item['productItemId']?.toString();
          // productItem 관계 데이터에서도 ID 추출 (서버가 포함해서 보내줌)
          final productItemRelId = (item['productItem'] as Map<String, dynamic>?)?['id']?.toString();
          // 둘 중 유효한 값 사용 (productItemId 우선)
          final itemId = (productItemId != null && productItemId.isNotEmpty)
              ? productItemId
              : (productItemRelId != null && productItemRelId.isNotEmpty)
                  ? productItemRelId
                  : item['productId']?.toString() ?? '';
          final cartId = item['id']?.toString() ?? '';
          if (itemId.isNotEmpty) {
            _cartItemIds.add(itemId);
            if (cartId.isNotEmpty) _cartItemIdMap[itemId] = cartId;
          }
        }
      });
    }
  }

  // 장바구니에 추가 (productItemId 기준)
  Future<void> _addToCart(Map<String, dynamic> item) async {
    final itemId = item['id'] as String;       // 2뎁스 상세 품목 ID
    final productId = item['productId'] as String; // 1뎁스 품목 ID

    // 낙관적 UI 업데이트 (즉시 체크 표시)
    setState(() => _cartItemIds.add(itemId));

    final result = await _cartService.addItem(
      productId: productId,
      eventId: widget.eventId,
      productItemId: itemId,  // 2뎁스 ID도 전송 (가격 연결용)
    );

    if (!mounted) return;

    if (result['success'] == true && result['item'] != null) {
      // 서버 응답에서 cartItemId 저장 (삭제용)
      final cartId = result['item']['id']?.toString() ?? '';
      if (cartId.isNotEmpty) {
        _cartItemIdMap[itemId] = cartId;
      }
    } else {
      // 서버 실패 시 롤백 (체크 표시 되돌리기)
      setState(() => _cartItemIds.remove(itemId));
    }
  }

  // 장바구니에서 제거
  Future<void> _removeFromCart(String itemId) async {
    final cartItemId = _cartItemIdMap[itemId];
    if (cartItemId == null) return;

    setState(() {
      _cartItemIds.remove(itemId);
      _cartItemIdMap.remove(itemId);
    });

    await _cartService.removeItem(cartItemId);
  }

  // 장바구니 토글 (담기/빼기)
  Future<void> _toggleCart(Map<String, dynamic> item) async {
    final itemId = item['id'] as String;
    if (_cartItemIds.contains(itemId)) {
      await _removeFromCart(itemId);
    } else {
      await _addToCart(item);
    }
  }

  // 품목 상세 팝업 (디자인: 6.고객용-품목 상세.jpg)
  void _showItemDetail(Map<String, dynamic> item) {
    final isInCart = _cartItemIds.contains(item['id']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 카테고리명 + 닫기
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['category'] ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 업체명
            Text(
              item['vendorName'] ?? '',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            // 패키지명
            Text(
              item['name'] ?? '',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            // 설명
            if ((item['description'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                item['description'],
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            // 가격
            RichText(
              text: TextSpan(children: [
                const TextSpan(
                  text: '가격 : ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
                TextSpan(
                  text: '${_priceFormat.format(item['price'])}원',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.priceRed),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            // 장바구니 담기/빼기 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _toggleCart(item);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInCart ? AppColors.textSecondary : AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: Text(isInCart ? '장바구니에서 빼기' : '장바구니 담기'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 탭 전환 — IndexedStack으로 즉시 전환 (Navigator.push 없음)
  void _onTabChanged(int index) {
    if (index == _currentTabIndex) return;
    setState(() => _currentTabIndex = index);
    // 홈 탭으로 돌아올 때 장바구니 변경사항 반영
    if (index == 0) _loadCartItems();
  }

  // 탭별 AppBar 제목
  String get _appBarTitle {
    switch (_currentTabIndex) {
      case 2: return '계약함';
      case 3: return '마이페이지';
      default: return widget.eventTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(
        title: _appBarTitle,
        showBackButton: false,
      ),
      // IndexedStack: 모든 탭 위젯을 유지하며 현재 탭만 표시
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          // 탭 0: 홈 (구매 품목 리스트)
          _buildHomeBody(),
          // 탭 1: 장바구니
          CartScreen(
            eventId: widget.eventId,
            eventTitle: widget.eventTitle,
            embedded: true,
          ),
          // 탭 2: 계약함
          const CustomerContractScreen(embedded: true),
          // 탭 3: 마이페이지
          const MypageScreen(role: 'CUSTOMER', embedded: true),
        ],
      ),
      // 하단 탭바 — 장바구니 아이콘에 담긴 수량 배지 표시
      bottomNavigationBar: AppTabBar.customer(
        currentIndex: _currentTabIndex,
        onTap: _onTabChanged,
        cartBadgeCount: _cartItemIds.length,
      ),
    );
  }

  // 홈 탭 본문 (구매 품목 리스트)
  Widget _buildHomeBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "구매 품목 리스트 >" + 내 타입 뱃지
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            children: [
              const Text(
                '구매 품목 리스트',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
              const Spacer(),
              // 내 타입 뱃지
              if (_myHousingType != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$_myHousingType타입',
                    style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        // 품목 목록
        Expanded(child: _buildProductList()),
      ],
    );
  }

  // 품목 목록 (1뎁스 아코디언 → 2뎁스 카드)
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: _products.asMap().entries.map((entry) => _buildCategoryAccordion(entry.value, index: entry.key)).toList(),
    );
  }

  // 1뎁스 카테고리 아코디언 (줄눈, 나노코팅 등)
  // - 모든 아코디언 펼침 상태로 시작
  // - 접힌 상태에서도 첫 1개 상세 품목 노출
  Widget _buildCategoryAccordion(Map<String, dynamic> product, {int index = 0}) {
    final items = product['items'] as List<Map<String, dynamic>>? ?? [];
    final category = product['category'] as String? ?? product['name'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: _ExpandableProductTile(
        category: category,
        items: items,
        // 첫번째 품목(index 0)만 이미지 표시, 나머지는 이미지 영역 없음
        itemBuilder: (item, index) => _buildItemCard(item, isFirstItem: index == 0),
      ),
    );
  }

  // 2뎁스 상세 품목 카드
  // isFirstItem: true이면 좌측 이미지 썸네일 표시, false이면 이미지 자리만큼 패딩
  Widget _buildItemCard(Map<String, dynamic> item, {bool isFirstItem = false}) {
    final isInCart = _cartItemIds.contains(item['id']);
    final formattedPrice = _priceFormat.format(item['price']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 썸네일 — 첫번째 품목만 표시, 나머지는 동일 너비 패딩으로 정렬 맞춤
          if (isFirstItem) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 72,
                height: 72,
                color: AppColors.background,
                child: buildSmartImage(
                  item['imageUrl'] as String?,
                  width: 72,
                  height: 72,
                  placeholder: const Icon(Icons.image_outlined, color: AppColors.textHint),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            // 이미지 없는 품목도 동일한 왼쪽 여백으로 텍스트 라인 정렬
            const SizedBox(width: 84), // 72(이미지) + 12(간격)
          ],
          // 품목 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 업체명 + 상세보기 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['vendorName'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => _showItemDetail(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('상세보기', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // 패키지명
                Text(item['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                // 설명
                if ((item['description'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(item['description'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                // 가격 + 장바구니 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        const TextSpan(text: '가격 : ', style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                        TextSpan(text: '$formattedPrice원', style: const TextStyle(fontSize: 14, color: AppColors.priceRed, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    // 장바구니 담기 / 파란 V 체크 (탭으로 토글)
                    GestureDetector(
                      onTap: () => _toggleCart(item),
                      child: isInCart
                          ? Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: AppColors.white, size: 18),
                            )
                          : Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: AppColors.textSecondary, size: 18),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 모든 아코디언 펼침 + 접혀도 첫 1개 품목 노출하는 커스텀 타일
class _ExpandableProductTile extends StatefulWidget {
  final String category;
  final List<Map<String, dynamic>> items;
  // itemBuilder(item, index) — index로 첫번째 품목 여부 판단
  final Widget Function(Map<String, dynamic>, int) itemBuilder;

  const _ExpandableProductTile({
    required this.category,
    required this.items,
    required this.itemBuilder,
  });

  @override
  State<_ExpandableProductTile> createState() => _ExpandableProductTileState();
}

class _ExpandableProductTileState extends State<_ExpandableProductTile> {
  bool _isExpanded = false; // 기본 접힘 상태로 변경

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 (탭으로 접기/펼치기)
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.category, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        // 내용: 펼침 시 전체, 접힘 시 첫 1개 + 클릭 가능한 "더보기"
        if (widget.items.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('등록된 패키지가 없습니다', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                if (_isExpanded)
                  ...widget.items.asMap().entries.map((e) => widget.itemBuilder(e.value, e.key))
                else ...[
                  // 접힌 상태: 첫 1개만 표시
                  widget.itemBuilder(widget.items.first, 0),
                  // "외 N개 더보기" — 클릭하면 아코디언 펼침
                  if (widget.items.length > 1)
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = true),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '외 ${widget.items.length - 1}개 더보기',
                              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.expand_more, size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
