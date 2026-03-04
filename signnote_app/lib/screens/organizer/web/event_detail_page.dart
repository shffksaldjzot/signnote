import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../widgets/common/app_card.dart';
import '../../../services/event_service.dart';
import '../../../services/product_service.dart';
import '../../../services/contract_service.dart';

// ============================================
// 행사 상세 페이지 (Event Detail Page)
//
// 구조:
// ┌──────────────────────────────────────────┐
// | ← 창원 자이 박람회                        |
// | 참여코드: 123456 [복사]  기간: 03.01~03.03|
// ├──────────────────────────────────────────┤
// | [상품 목록]  [계약 현황]         탭 전환    |
// ├──────────────────────────────────────────┤
// | (상품 탭)                                |
// | 카테고리 | 업체명 | 상품명 | 가격 | 타입   |
// |                                          |
// | (계약 탭)                                |
// | 고객명 | 상품명 | 계약금 | 상태 | 날짜     |
// └──────────────────────────────────────────┘
// ============================================

class EventDetailPage extends StatefulWidget {
  final String eventId;  // URL에서 받은 행사 ID

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  final ProductService _productService = ProductService();
  final ContractService _contractService = ContractService();

  late TabController _tabController;  // 상품/계약 탭 전환
  bool _isLoading = true;

  Map<String, dynamic> _event = {};     // 행사 상세 정보
  List<dynamic> _products = [];         // 상품 목록
  List<dynamic> _contracts = [];        // 계약 목록

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 데이터 불러오기 (행사 상세 + 상품 + 계약)
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 행사 상세 조회
    final eventResult = await _eventService.getEventDetail(widget.eventId);
    if (eventResult['success'] == true) {
      _event = eventResult['event'] ?? {};
    }

    // 상품 목록 조회
    final productResult = await _productService.getProductsByEvent(widget.eventId);
    if (productResult['success'] == true) {
      _products = productResult['products'] as List? ?? [];
    }

    // 계약 목록 조회
    final contractResult = await _contractService.getEventContracts(widget.eventId);
    if (contractResult['success'] == true) {
      _contracts = contractResult['contracts'] as List? ?? [];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // 참여코드 복사
  void _copyEntryCode() {
    final code = _event['entryCode']?.toString() ?? '';
    if (code.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참여코드가 복사되었습니다')),
      );
    }
  }

  // 날짜 포맷팅
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy.MM.dd').format(date);
    } catch (_) {
      return '-';
    }
  }

  // 계약 상태 한글 변환
  String _getStatusText(String? status) {
    switch (status) {
      case 'PENDING':
        return '결제 대기';
      case 'CONFIRMED':
        return '결제 완료';
      case 'CANCEL_REQUESTED':
        return '취소 요청';
      case 'CANCELLED':
        return '취소 완료';
      default:
        return '-';
    }
  }

  // 상태별 색상
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;
      case 'CONFIRMED':
        return AppColors.success;
      case 'CANCEL_REQUESTED':
        return AppColors.priceRed;
      case 'CANCELLED':
        return AppColors.textSecondary;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 상단: 뒤로가기 + 행사명 ──
          Row(
            children: [
              // 뒤로가기 버튼 → 행사 관리 목록으로
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(AppRoutes.organizerWebEvents),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _event['title'] ?? '행사 상세',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── 행사 기본 정보 (참여코드, 기간) ──
          _isLoading
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Row(
                    children: [
                      // 참여코드 + 복사 버튼
                      Text(
                        '참여코드: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _event['entryCode'] ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: _copyEntryCode,
                        tooltip: '참여코드 복사',
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 24),
                      // 행사 기간
                      Text(
                        '기간: ${_formatDate(_event['startDate']?.toString())} ~ ${_formatDate(_event['endDate']?.toString())}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 24),

          // ── 탭 바 (상품 목록 / 계약 현황) ──
          AppCard(
            padding: EdgeInsets.zero,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: '상품 목록'),
                Tab(text: '계약 현황'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 탭 내용 ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // 탭 1: 상품 목록
                      _buildProductsTab(numberFormat),
                      // 탭 2: 계약 현황
                      _buildContractsTab(numberFormat),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // 상품 목록 탭
  Widget _buildProductsTab(NumberFormat numberFormat) {
    if (_products.isEmpty) {
      return const Center(
        child: Text('등록된 상품이 없습니다', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.background),
            columnSpacing: 24,
            horizontalMargin: 20,
            columns: const [
              DataColumn(label: Text('카테고리', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('업체명', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('상품명', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('가격', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('타입', style: TextStyle(fontWeight: FontWeight.w600))),
            ],
            rows: _products.map((product) {
              final price = product['price'] ?? 0;
              final types = (product['housingTypes'] as List?)?.join(', ') ?? '-';

              return DataRow(cells: [
                DataCell(Text(product['category'] ?? '-')),
                DataCell(Text(product['vendorName'] ?? '-')),
                DataCell(Text(product['name'] ?? '-')),
                DataCell(Text(
                  '${numberFormat.format(price)}원',
                  style: const TextStyle(
                    color: AppColors.priceRed,
                    fontWeight: FontWeight.w600,
                  ),
                )),
                DataCell(Text(types)),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  // 계약 현황 탭
  Widget _buildContractsTab(NumberFormat numberFormat) {
    if (_contracts.isEmpty) {
      return const Center(
        child: Text('계약 내역이 없습니다', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.background),
            columnSpacing: 24,
            horizontalMargin: 20,
            columns: const [
              DataColumn(label: Text('고객명', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('상품명', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('계약금', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('날짜', style: TextStyle(fontWeight: FontWeight.w600))),
            ],
            rows: _contracts.map((contract) {
              final deposit = contract['depositAmount'] ?? 0;
              final status = contract['status']?.toString();
              final statusText = _getStatusText(status);
              final statusColor = _getStatusColor(status);

              // 고객명: customer 객체에서 가져오기
              final customer = contract['customer'] as Map<String, dynamic>?;
              final customerName = customer?['name'] ?? '-';

              // 상품명: product 객체에서 가져오기
              final product = contract['product'] as Map<String, dynamic>?;
              final productName = product?['name'] ?? '-';

              return DataRow(cells: [
                DataCell(Text(customerName)),
                DataCell(Text(productName)),
                DataCell(Text(
                  '${numberFormat.format(deposit)}원',
                  style: const TextStyle(
                    color: AppColors.priceRed,
                    fontWeight: FontWeight.w600,
                  ),
                )),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(_formatDate(contract['createdAt']?.toString()))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
