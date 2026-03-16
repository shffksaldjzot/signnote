import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/product_service.dart';
import '../../services/event_service.dart';

// ============================================
// 품목 관리 페이지 (Products Page)
//
// 구조 (1뎁스/2뎁스 계층):
// ┌─ 필터 바 ──────────────────────────────────┐
// | [행사 선택 ▼]  [검색어 입력]                  |
// └────────────────────────────────────────────┘
//
// ┌─ 품목 테이블 (확장형) ───────────────────────┐
// | ▶ 줄눈    | ○○업체 | 20% | 500,000원 | 창원 |
// |   ├ A패키지     | 84A,84B  | 350,000원      |
// |   └ B패키지     | 전체타입  | 500,000원      |
// | ▶ 나노코팅 | △△업체 | 15% | 300,000원 | 창원 |
// |   └ 기본        | 84A      | 200,000원      |
// └────────────────────────────────────────────┘
// ============================================

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ProductService _productService = ProductService();
  final EventService _eventService = EventService();

  bool _isLoading = true;
  List<dynamic> _products = [];        // 전체 품목 목록 (1뎁스 + items)
  List<dynamic> _events = [];          // 행사 목록 (필터용)
  String? _selectedEventId;            // 선택된 행사 필터
  String _searchQuery = '';            // 검색어

  // 가격 포맷 (1000 → 1,000)
  final _priceFormat = NumberFormat('#,###', 'ko_KR');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 행사 목록 + 품목 목록 동시 로딩
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final eventResult = await _eventService.getEvents();
    if (eventResult['success'] == true) {
      _events = eventResult['events'] ?? [];
    }

    await _loadProducts();
  }

  // 품목 목록만 다시 불러오기
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    final result = await _productService.getAllProducts(
      eventId: _selectedEventId,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _products = result['products'] ?? [];
        }
      });
    }
  }

  // 검색어로 필터링된 품목 목록
  List<dynamic> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    final query = _searchQuery.toLowerCase();
    return _products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final vendor = (p['vendorName'] ?? '').toString().toLowerCase();
      final category = (p['category'] ?? '').toString().toLowerCase();
      // 2뎁스 아이템명도 검색
      final items = p['items'] as List? ?? [];
      final itemMatch = items.any((item) =>
        (item['name'] ?? '').toString().toLowerCase().contains(query));
      return name.contains(query) || vendor.contains(query) ||
             category.contains(query) || itemMatch;
    }).toList();
  }

  // 총 상세 품목 수 계산
  int get _totalItemCount {
    int count = 0;
    for (final p in _filteredProducts) {
      count += (p['items'] as List?)?.length ?? 0;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 페이지 제목 ──
          const Text(
            '품목 관리',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '품목 ${_filteredProducts.length}개 · 상세 품목 $_totalItemCount개',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),

          // ── 필터 바 ──
          _buildFilterBar(),
          const SizedBox(height: 16),

          // ── 품목 테이블 (확장형) ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('등록된 품목이 없습니다'))
                    : _buildProductList(),
          ),
        ],
      ),
    );
  }

  // 필터 바 위젯
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          // 행사 필터 드롭다운
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedEventId,
              decoration: const InputDecoration(
                labelText: '행사 선택',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('전체 행사')),
                ..._events.map((e) => DropdownMenuItem(
                  value: e['id']?.toString(),
                  child: Text(e['title'] ?? '', overflow: TextOverflow.ellipsis),
                )),
              ],
              onChanged: (value) {
                _selectedEventId = value;
                _loadProducts();
              },
            ),
          ),
          const SizedBox(width: 12),

          // 검색어 입력
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                labelText: '검색',
                hintText: '품목명, 업체명, 패키지명으로 검색',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ],
      ),
    );
  }

  // 품목 목록 (1뎁스 확장 → 2뎁스 하위 행)
  Widget _buildProductList() {
    final products = _filteredProducts;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // 테이블 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 32), // 확장 아이콘 공간
                  Expanded(flex: 3, child: Text('품목명', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(flex: 2, child: Text('배정 업체', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(flex: 1, child: Text('수수료', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('참가비', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right)),
                  Expanded(flex: 2, child: Text('행사', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right)),
                ],
              ),
            ),
            const Divider(height: 1),
            // 1뎁스 품목 행 (확장 가능)
            ...products.map((product) => _buildProductRow(product)),
          ],
        ),
      ),
    );
  }

  // 1뎁스 품목 행 (ExpansionTile)
  Widget _buildProductRow(dynamic product) {
    final items = product['items'] as List? ?? [];
    final vendorName = product['vendorName'] ?? product['vendor']?['name'] ?? '미배정';
    final commissionRate = product['commissionRate'];
    final rateText = commissionRate is num ? '${(commissionRate * 100).toStringAsFixed(0)}%' : '0%';
    final participationFee = product['participationFee'] ?? 0;
    final eventTitle = product['event']?['title'] ?? '-';
    final hasVendor = vendorName != null && vendorName != '미배정' && vendorName.toString().isNotEmpty;

    return Column(
      children: [
        ExpansionTile(
          shape: const Border(), // 펼쳤을 때 까만 줄 제거
          collapsedShape: const Border(), // 접혔을 때 까만 줄 제거
          tilePadding: const EdgeInsets.symmetric(horizontal: 20),
          childrenPadding: EdgeInsets.zero,
          leading: Icon(
            items.isNotEmpty ? Icons.expand_more : Icons.remove,
            size: 20,
            color: items.isNotEmpty ? AppColors.textPrimary : AppColors.textHint,
          ),
          title: Row(
            children: [
              // 품목명 + 카테고리 칩
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    _buildCategoryChip(product['category'] ?? ''),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        product['name'] ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // 배정 업체
              Expanded(
                flex: 2,
                child: Text(
                  hasVendor ? vendorName : '미배정',
                  style: TextStyle(
                    fontSize: 13,
                    color: hasVendor ? AppColors.textPrimary : AppColors.textHint,
                    fontWeight: hasVendor ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              // 수수료
              Expanded(
                flex: 1,
                child: Text(rateText, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
              ),
              // 참가비
              Expanded(
                flex: 2,
                child: Text(
                  participationFee > 0 ? '${_priceFormat.format(participationFee)}원' : '-',
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.right,
                ),
              ),
              // 행사
              Expanded(
                flex: 2,
                child: Text(eventTitle, style: const TextStyle(fontSize: 13), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          children: [
            // 2뎁스 상세 품목 행들
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 8, 20, 16),
                child: Text(
                  hasVendor ? '업체가 아직 상세 품목을 등록하지 않았습니다' : '업체 배정 후 상세 품목이 표시됩니다',
                  style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
              )
            else
              ...items.map((item) => _buildItemRow(item)),
          ],
        ),
        const Divider(height: 1),
      ],
    );
  }

  // 2뎁스 상세 품목 행
  Widget _buildItemRow(dynamic item) {
    final price = item['price'] ?? 0;
    final housingTypes = (item['housingTypes'] as List?)?.join(', ') ?? '-';

    return Container(
      padding: const EdgeInsets.fromLTRB(72, 10, 20, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          // 들여쓰기 표시
          const Text('└ ', style: TextStyle(color: AppColors.textHint)),
          // 패키지명
          Expanded(
            flex: 3,
            child: Text(item['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          // 적용 타입
          Expanded(
            flex: 2,
            child: Text(housingTypes, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ),
          // 가격
          Expanded(
            flex: 2,
            child: Text(
              '${_priceFormat.format(price)}원',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
          // 설명 (tooltip)
          const Expanded(flex: 2, child: SizedBox()),
        ],
      ),
    );
  }

  // 카테고리 칩 위젯
  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category,
        style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
