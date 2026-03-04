import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../services/product_service.dart';
import '../../../services/event_service.dart';

// ============================================
// 품목 관리 페이지 (Products Page)
//
// 구조:
// ┌─ 필터 바 ──────────────────────────────────┐
// | [행사 선택 ▼]  [카테고리 ▼]  [검색어 입력]   |
// └────────────────────────────────────────────┘
//
// ┌─ 품목 테이블 ──────────────────────────────┐
// | 상품명 | 카테고리 | 업체명 | 가격 | 행사    |
// └────────────────────────────────────────────┘
//
// 데이터: ProductService.findAll (주관사 전용 API)
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
  List<dynamic> _products = [];        // 전체 상품 목록
  List<dynamic> _events = [];          // 행사 목록 (필터용)
  String? _selectedEventId;            // 선택된 행사 필터
  String? _selectedCategory;           // 선택된 카테고리 필터
  String _searchQuery = '';            // 검색어

  // 가격 포맷 (1000 → 1,000)
  final _priceFormat = NumberFormat('#,###', 'ko_KR');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 행사 목록 + 상품 목록 동시 로딩
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 행사 목록 가져오기 (필터 드롭다운용)
    final eventResult = await _eventService.getEvents();
    if (eventResult['success'] == true) {
      _events = eventResult['events'] ?? [];
    }

    // 상품 목록 가져오기
    await _loadProducts();
  }

  // 상품 목록만 다시 불러오기 (필터 변경 시)
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    final result = await _productService.getAllProducts(
      eventId: _selectedEventId,
      category: _selectedCategory,
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

  // 검색어로 필터링된 상품 목록
  List<dynamic> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    final query = _searchQuery.toLowerCase();
    return _products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final vendor = (p['vendorName'] ?? '').toString().toLowerCase();
      final category = (p['category'] ?? '').toString().toLowerCase();
      return name.contains(query) || vendor.contains(query) || category.contains(query);
    }).toList();
  }

  // 카테고리 목록 추출 (중복 제거)
  List<String> get _categories {
    final cats = _products.map((p) => p['category']?.toString() ?? '').toSet();
    cats.remove('');
    return cats.toList()..sort();
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
            '전체 ${_filteredProducts.length}개 품목',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),

          // ── 필터 바 ──
          _buildFilterBar(),
          const SizedBox(height: 16),

          // ── 상품 테이블 ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('등록된 품목이 없습니다'))
                    : _buildProductTable(),
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

          // 카테고리 필터 드롭다운
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('전체 카테고리')),
                ..._categories.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedCategory = value);
                _loadProducts();
              },
            ),
          ),
          const SizedBox(width: 12),

          // 검색어 입력
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: '검색',
                hintText: '상품명, 업체명으로 검색',
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

  // 상품 테이블 위젯
  Widget _buildProductTable() {
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
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('상품명', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('카테고리', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('업체명', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('가격', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('평형', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('행사', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: products.map<DataRow>((p) {
            final price = p['price'] ?? 0;
            final housingTypes = (p['housingTypes'] as List?)?.join(', ') ?? '-';
            final eventTitle = p['event']?['title'] ?? '-';

            return DataRow(cells: [
              DataCell(Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(_buildCategoryChip(p['category'] ?? '')),
              DataCell(Text(p['vendorName'] ?? p['vendor']?['name'] ?? '-')),
              DataCell(Text('${_priceFormat.format(price)}원',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
              DataCell(Text(housingTypes, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
              DataCell(Text(eventTitle, overflow: TextOverflow.ellipsis)),
            ]);
          }).toList(),
        ),
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
        style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
