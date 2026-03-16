import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/event_service.dart';
import '../../services/product_service.dart';
import '../../services/contract_service.dart';

// ============================================
// 품목 상세 페이지 (Product Detail) — 3뎁스
//
// Breadcrumb: 행사 관리 > [행사명] > [품목명]
//
// 3개 섹션:
// 1. 주관사 관점: 품목 정보 (업체배정/수수료/참가비)
// 2. 협력업체 관점: 상세품목(패키지) 목록
// 3. 고객 관점: 이 품목의 계약/장바구니 현황
// ============================================

class ProductDetailPage extends StatefulWidget {
  final String eventId;
  final String productId;

  const ProductDetailPage({super.key, required this.eventId, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final EventService _eventService = EventService();
  final ProductService _productService = ProductService();
  final ContractService _contractService = ContractService();
  final _priceFormat = NumberFormat('#,###', 'ko_KR');

  bool _isLoading = true;
  Map<String, dynamic> _event = {};
  Map<String, dynamic> _product = {};
  List<dynamic> _productItems = [];
  List<dynamic> _productContracts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 행사 정보 (breadcrumb 용)
    final eventResult = await _eventService.getEventDetail(widget.eventId);
    if (eventResult['success'] == true) {
      _event = eventResult['event'] ?? {};
    }

    // 품목 상세
    final productResult = await _productService.getProductDetail(widget.productId);
    if (productResult['success'] == true) {
      _product = productResult['product'] ?? {};
    }

    // 상세품목 목록
    final itemsResult = await _productService.getProductItems(widget.productId);
    if (itemsResult['success'] == true) {
      _productItems = itemsResult['items'] as List? ?? [];
    }

    // 이 행사의 계약 중 이 품목에 해당하는 것만 필터링
    final contractResult = await _contractService.getEventContracts(widget.eventId);
    if (contractResult['success'] == true) {
      final allContracts = contractResult['contracts'] as List? ?? [];
      _productContracts = allContracts.where((c) =>
        c['productId']?.toString() == widget.productId
      ).toList();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final vendorName = _product['vendorName'] ?? _product['vendor']?['name'] ?? '미배정';
    final hasVendor = vendorName != '미배정' && vendorName.toString().isNotEmpty;
    final rate = _product['commissionRate'];
    final rateText = rate is num ? '${(rate * 100).toStringAsFixed(0)}%' : '0%';
    final fee = _product['participationFee'] ?? 0;
    final paid = _product['feePaymentConfirmed'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Breadcrumb ──
          Row(
            children: [
              InkWell(
                onTap: () => context.go(AppRoutes.organizerWebEvents),
                child: const Text('행사 관리', style: TextStyle(fontSize: 14, color: AppColors.primary)),
              ),
              const Text('  >  ', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
              InkWell(
                onTap: () => context.go('/admin/events/${widget.eventId}'),
                child: Text(
                  _event['title'] ?? '행사',
                  style: const TextStyle(fontSize: 14, color: AppColors.primary),
                ),
              ),
              const Text('  >  ', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
              Text(
                _product['name'] ?? '품목',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ═══════════════════════════════════════
          // 섹션 1: 주관사 관점 — 품목 정보
          // ═══════════════════════════════════════
          _buildSectionHeader('주관사 관점', Icons.business_center, AppColors.organizer),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                _buildInfoField('품목명', _product['name'] ?? '-'),
                _buildInfoField('카테고리', _product['category'] ?? '-'),
                _buildInfoField('배정 업체', hasVendor ? vendorName : '미배정',
                  valueColor: hasVendor ? AppColors.textPrimary : AppColors.textHint),
                _buildInfoField('수수료율', rateText),
                _buildInfoField('참가비', fee > 0 ? '${_priceFormat.format(fee)}원' : '미설정'),
                _buildInfoField('입금 확인', paid ? '입금완료' : '미입금',
                  valueColor: paid ? AppColors.success : AppColors.priceRed),
                _buildInfoField('정렬 순서', '${_product['sortOrder'] ?? 0}'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════
          // 섹션 2: 협력업체 관점 — 상세품목 목록
          // ═══════════════════════════════════════
          _buildSectionHeader('협력업체 관점 — 상세품목 (${_productItems.length}개)', Icons.inventory_2, AppColors.vendor),
          const SizedBox(height: 12),
          if (_productItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  hasVendor ? '업체가 아직 상세 품목을 등록하지 않았습니다' : '업체를 배정해야 상세 품목이 등록됩니다',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 14),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.background),
                  columnSpacing: 24,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(label: Text('패키지명', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('적용 타입', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('가격', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('설명', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                  rows: _productItems.map((item) {
                    final price = item['price'] ?? 0;
                    final types = (item['housingTypes'] as List?)?.join(', ') ?? '-';
                    return DataRow(cells: [
                      DataCell(Text(item['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(types, style: const TextStyle(fontSize: 13))),
                      DataCell(Text(
                        '${_priceFormat.format(price)}원',
                        style: const TextStyle(color: AppColors.priceRed, fontWeight: FontWeight.w600),
                      )),
                      DataCell(Text(
                        item['description'] ?? '-',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 32),

          // ═══════════════════════════════════════
          // 섹션 3: 고객 관점 — 계약/장바구니
          // ═══════════════════════════════════════
          _buildSectionHeader('고객 관점 — 이 품목의 계약 (${_productContracts.length}건)', Icons.people, AppColors.customer),
          const SizedBox(height: 12),
          if (_productContracts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text('이 품목의 계약이 없습니다', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.background),
                  columnSpacing: 24,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(label: Text('고객명', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('전화번호', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('선택 패키지', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('계약금', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('날짜', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                  rows: _productContracts.map((c) {
                    final customer = c['customer'] as Map<String, dynamic>?;
                    final productItem = c['productItem'] as Map<String, dynamic>?;
                    final deposit = c['depositAmount'] ?? 0;
                    final status = c['status']?.toString();
                    final statusText = _getStatusText(status);
                    final statusColor = _getStatusColor(status);

                    return DataRow(cells: [
                      DataCell(Text(customer?['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(customer?['phone'] ?? '-')),
                      DataCell(Text(productItem?['name'] ?? '-')),
                      DataCell(Text('${_priceFormat.format(deposit)}원', style: const TextStyle(color: AppColors.priceRed, fontWeight: FontWeight.w600))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                      )),
                      DataCell(Text(_formatDate(c['createdAt']?.toString()))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 섹션 헤더
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // 정보 필드
  Widget _buildInfoField(String label, String value, {Color? valueColor}) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try { return DateFormat('yyyy.MM.dd').format(DateTime.parse(dateStr)); }
    catch (_) { return '-'; }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'PENDING': return '대기';
      case 'CONFIRMED': return '확정';
      case 'CANCEL_REQUESTED': return '취소요청';
      case 'CANCELLED': return '취소';
      default: return '-';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING': return AppColors.warning;
      case 'CONFIRMED': return AppColors.success;
      case 'CANCEL_REQUESTED': return AppColors.priceRed;
      case 'CANCELLED': return AppColors.textSecondary;
      default: return AppColors.textHint;
    }
  }
}
