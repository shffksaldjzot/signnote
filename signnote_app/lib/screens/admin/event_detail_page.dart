import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/common/app_card.dart';
import '../../services/event_service.dart';
import '../../services/product_service.dart';
import '../../services/contract_service.dart';
import '../../services/settlement_service.dart';
import '../../services/notification_service.dart';
import '../../utils/image_download.dart';
import '../organizer/event_form_screen.dart';

// ============================================
// 행사 상세 페이지 (Event Detail Page) — 2뎁스
//
// Breadcrumb: 행사 관리 > [행사명]
// 탭: 품목관리 / 고객관리 / 계약현황 / 정산관리 / 알림
// ============================================

class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  final ProductService _productService = ProductService();
  final ContractService _contractService = ContractService();
  final SettlementService _settlementService = SettlementService();
  final NotificationService _notificationService = NotificationService();
  final _priceFormat = NumberFormat('#,###', 'ko_KR');

  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic> _event = {};
  List<dynamic> _products = [];
  List<dynamic> _participants = [];
  List<dynamic> _contracts = [];
  List<dynamic> _settlements = [];
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    // B-27: 요약 탭 추가 (5 → 6탭)
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 전체 데이터 로딩
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 행사 상세
    final eventResult = await _eventService.getEventDetail(widget.eventId);
    if (eventResult['success'] == true) {
      _event = eventResult['event'] ?? {};
    }

    // 품목 목록
    final productResult = await _productService.getProductsByEvent(widget.eventId);
    if (productResult['success'] == true) {
      _products = productResult['products'] as List? ?? [];
    }

    // 참여자 (고객) 목록
    final partResult = await _eventService.getParticipants(widget.eventId);
    if (partResult['success'] == true) {
      _participants = partResult['participants'] as List? ?? [];
    }

    // 계약 목록
    final contractResult = await _contractService.getEventContracts(widget.eventId);
    if (contractResult['success'] == true) {
      _contracts = contractResult['contracts'] as List? ?? [];
    }

    // 정산 목록
    final settleResult = await _settlementService.getAllSettlements(eventId: widget.eventId);
    if (settleResult['success'] == true) {
      _settlements = settleResult['settlements'] ?? [];
    }

    // 알림 목록
    final notiResult = await _notificationService.getNotificationsByEvent(widget.eventId);
    if (notiResult['success'] == true) {
      _notifications = notiResult['notifications'] ?? [];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // 참여코드 복사
  void _copyCode(String code, String label) {
    if (code.isNotEmpty && code != '------') {
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label 복사됨: $code')),
      );
    }
  }

  // 행사 편집 다이얼로그
  void _showEditDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 600,
          height: MediaQuery.of(context).size.height * 0.85,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scaffold(
              body: Stack(
                children: [
                  OrganizerEventFormScreen(event: _event.isNotEmpty ? _event : null),
                  Positioned(
                    top: 8, right: 8,
                    child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((result) {
      if (result == true) _loadData();
    });
  }

  // 행사 삭제 확인
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('행사 삭제'),
        content: Text("'${_event['title']}' 행사를 삭제하시겠습니까?\n\n삭제하면 관련된 모든 데이터가 삭제되며 복구할 수 없습니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _eventService.deleteEvent(widget.eventId);
              if (!mounted) return;
              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('행사가 삭제되었습니다')));
                context.go(AppRoutes.organizerWebEvents);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      return DateFormat('yyyy.MM.dd').format(DateTime.parse(dateStr));
    } catch (_) { return '-'; }
  }

  @override
  Widget build(BuildContext context) {
    final customerCode = _event['entryCode']?.toString() ?? '------';
    final vendorCode = _event['vendorEntryCode']?.toString() ?? '------';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Breadcrumb + 액션 버튼 ──
          Row(
            children: [
              // Breadcrumb
              InkWell(
                onTap: () => context.go(AppRoutes.organizerWebEvents),
                child: const Text('행사 관리', style: TextStyle(fontSize: 14, color: AppColors.primary)),
              ),
              const Text('  >  ', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
              Expanded(
                child: Text(
                  _event['title'] ?? '행사 상세',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 편집 버튼
              OutlinedButton.icon(
                onPressed: _showEditDialog,
                icon: Image.asset('assets/icons/vendor/write.png', width: 16, height: 16),
                label: const Text('행사 편집'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              const SizedBox(width: 8),
              // 삭제 버튼
              OutlinedButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('삭제'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── B-31: 행사 정보 바 (시각적 위계 개선) ──
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1행: 코드 (크게, 강조)
                  Row(
                    children: [
                      _buildCodeBox('고객코드', customerCode, AppColors.primary, () => _copyCode(customerCode, '고객코드')),
                      const SizedBox(width: 12),
                      _buildCodeBox('업체코드', vendorCode, AppColors.organizer, () => _copyCode(vendorCode, '업체코드')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 2행: 부가 정보 (작게)
                  Wrap(
                    spacing: 20,
                    runSpacing: 6,
                    children: [
                      _infoText('기간', '${_formatDate(_event['startDate']?.toString())} ~ ${_formatDate(_event['endDate']?.toString())}'),
                      _infoText('세대수', _priceFormat.format(_event['unitCount'] ?? 0)),
                      _infoText('주관사', _event['organizer']?['name'] ?? '-'),
                      _infoText('계약금', '${((_event['depositRate'] ?? 0.3) * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // ── 6개 탭 (B-27: 요약 탭 추가) ──
          AppCard(
            padding: EdgeInsets.zero,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              isScrollable: true, // 탭이 많아지면 가로 스크롤
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: [
                const Tab(text: '요약'),
                Tab(text: '품목관리 (${_products.length})'),
                Tab(text: '고객관리 (${_participants.where((p) => (p['role'] ?? p['user']?['role']) == 'CUSTOMER').length})'),
                Tab(text: '계약현황 (${_contracts.length})'),
                Tab(text: '정산관리 (${_settlements.length})'),
                Tab(text: '알림 (${_notifications.length})'),
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
                      _buildOverviewTab(), // B-27: 요약
                      _buildProductsTab(),
                      _buildCustomersTab(),
                      _buildContractsTab(),
                      _buildSettlementsTab(),
                      _buildNotificationsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // B-31: 코드 박스 (크게 강조)
  Widget _buildCodeBox(String label, String code, Color color, VoidCallback onCopy) {
    return Expanded(
      child: GestureDetector(
        onTap: onCopy,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Text('$label  ', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
              Text(code, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 3, color: color)),
              const Spacer(),
              Icon(Icons.copy, size: 14, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  // B-31: 부가 정보 텍스트 (작게)
  Widget _infoText(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: '$label ', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          TextSpan(text: value, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // B-27: 요약(Overview) 탭 — 핵심 지표 한눈에
  // ═══════════════════════════════════════════
  Widget _buildOverviewTab() {
    final customers = _participants.where((p) => (p['role'] ?? p['user']?['role']) == 'CUSTOMER').toList();
    final vendors = _participants.where((p) => (p['role'] ?? p['user']?['role']) == 'VENDOR').toList();
    final confirmedContracts = _contracts.where((c) => c['status'] == 'CONFIRMED').toList();
    final cancelRequested = _contracts.where((c) => c['status'] == 'CANCEL_REQUESTED').toList();
    final totalRevenue = confirmedContracts.fold<int>(0, (sum, c) => sum + ((c['depositAmount'] ?? 0) as int));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핵심 숫자 카드 4개
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _overviewCard('참여 업체', '${vendors.length}개', Icons.business, AppColors.organizer),
              _overviewCard('참여 고객', '${customers.length}명', Icons.people, AppColors.primary),
              _overviewCard('확정 계약', '${confirmedContracts.length}건', Icons.description, AppColors.success),
              _overviewCard('총 매출', '${_priceFormat.format(totalRevenue)}원', Icons.account_balance_wallet, AppColors.priceRed),
            ],
          ),
          const SizedBox(height: 16),

          // 처리 필요 알림
          if (cancelRequested.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Text('취소 요청 ${cancelRequested.length}건이 있습니다',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _tabController.animateTo(3), // 계약현황 탭으로 이동
                    child: const Text('확인하기', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),

          // 최근 계약 5건
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('최근 계약', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_contracts.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('계약 내역이 없습니다', style: TextStyle(color: AppColors.textHint)),
                  ))
                else
                  ...(_contracts.toList()
                    ..sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? '')))
                    .take(5)
                    .map((c) {
                      final customer = c['customer'] as Map<String, dynamic>?;
                      final product = c['product'] as Map<String, dynamic>?;
                      final status = c['status']?.toString() ?? '';
                      final statusText = _getContractStatusText(status);
                      final statusColor = _getContractStatusColor(status);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor), textAlign: TextAlign.center),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(customer?['name'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                            Text(product?['name'] ?? '-', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            const SizedBox(width: 12),
                            Text('${_priceFormat.format(c['depositAmount'] ?? 0)}원',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.priceRed)),
                          ],
                        ),
                      );
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 요약 카드 개별
  Widget _overviewCard(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 탭 2: 품목관리 — 클릭하면 3뎁스로 드릴다운
  // ═══════════════════════════════════════════
  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return const Center(child: Text('등록된 품목이 없습니다', style: TextStyle(color: AppColors.textSecondary)));
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
              DataColumn(label: Text('품목명', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('배정업체', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('수수료', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('참가비', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('입금', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('상세품목', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.w600))),
            ],
            rows: _products.map((product) {
              final vendorName = product['vendorName'] ?? product['vendor']?['name'] ?? '미배정';
              final hasVendor = vendorName != '미배정' && vendorName.toString().isNotEmpty;
              final rate = product['commissionRate'];
              final rateText = rate is num ? '${(rate * 100).toStringAsFixed(0)}%' : '0%';
              final fee = product['participationFee'] ?? 0;
              final paid = product['feePaymentConfirmed'] == true;
              final itemCount = (product['items'] as List?)?.length ?? 0;

              return DataRow(
                cells: [
                  // 품목명 — 클릭 시 3뎁스 상세로 이동
                  DataCell(
                    Text(product['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.primary)),
                    onTap: () {
                      final productId = product['id']?.toString() ?? '';
                      context.go('/admin/events/${widget.eventId}/products/$productId');
                    },
                  ),
                  DataCell(Text(
                    hasVendor ? vendorName : '미배정',
                    style: TextStyle(color: hasVendor ? AppColors.textPrimary : AppColors.textHint),
                  )),
                  DataCell(Text(rateText)),
                  DataCell(Text(fee > 0 ? '${_priceFormat.format(fee)}원' : '-')),
                  DataCell(paid
                    ? const Icon(Icons.check_circle, color: AppColors.success, size: 18)
                    : const Icon(Icons.cancel, color: AppColors.priceRed, size: 18)),
                  DataCell(Text('$itemCount개', style: const TextStyle(color: AppColors.textSecondary))),
                  DataCell(const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 탭 2: 고객관리 — 참여 고객 리스트
  // ═══════════════════════════════════════════
  Widget _buildCustomersTab() {
    // 플랫 구조(role 직접) 또는 중첩 구조(user.role) 모두 지원
    final customers = _participants.where((p) =>
      (p['role'] ?? p['user']?['role']) == 'CUSTOMER'
    ).toList();

    if (customers.isEmpty) {
      return const Center(child: Text('참여한 고객이 없습니다', style: TextStyle(color: AppColors.textSecondary)));
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
              DataColumn(label: Text('이름', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('전화번호', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('동', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('호', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('타입', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('참여일', style: TextStyle(fontWeight: FontWeight.w600))),
            ],
            rows: customers.map((p) {
              return DataRow(cells: [
                DataCell(Text(p['name'] ?? p['user']?['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text(p['phone'] ?? p['user']?['phone'] ?? '-')),
                DataCell(Text(p['dong'] ?? '-')),
                DataCell(Text(p['ho'] ?? '-')),
                DataCell(Text(p['housingType'] ?? '-')),
                DataCell(Text(_formatDate(p['joinedAt']?.toString()))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 탭 3: 계약현황
  // ═══════════════════════════════════════════
  // B-29: 계약 상태 필터 상태
  String _contractStatusFilter = '전체';

  Widget _buildContractsTab() {
    if (_contracts.isEmpty) {
      return const Center(child: Text('계약 내역이 없습니다', style: TextStyle(color: AppColors.textSecondary)));
    }

    // B-29: 상태 필터 적용
    final filteredContracts = _contractStatusFilter == '전체'
        ? _contracts
        : _contracts.where((c) => _getContractStatusText(c['status']?.toString()) == _contractStatusFilter).toList();

    return Column(
      children: [
        // B-29: 상태 필터 칩
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: ['전체', '확정', '대기', '취소요청', '취소'].map((status) {
              final isSelected = _contractStatusFilter == status;
              final count = status == '전체' ? _contracts.length
                  : _contracts.where((c) => _getContractStatusText(c['status']?.toString()) == status).length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _contractStatusFilter = status),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      '$status ($count)',
                      style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // 테이블
        Expanded(
          child: AppCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.background),
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 64,
                  columnSpacing: 20,
                  horizontalMargin: 20,
                  showCheckboxColumn: false,
                  columns: [
                    const DataColumn(label: Text('고객명', style: TextStyle(fontWeight: FontWeight.w600))),
                    const DataColumn(label: Text('품목', style: TextStyle(fontWeight: FontWeight.w600))),
                    const DataColumn(label: Text('패키지', style: TextStyle(fontWeight: FontWeight.w600))),
                    const DataColumn(label: Text('총 금액', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text(
                      '계약금 (${((_event['depositRate'] ?? 0.3) * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )),
                    const DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.w600))),
                    const DataColumn(label: Text('날짜', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                  rows: filteredContracts.map((c) {
                    final customer = c['customer'] as Map<String, dynamic>?;
                    final product = c['product'] as Map<String, dynamic>?;
                    final productItem = c['productItem'] as Map<String, dynamic>?;
                    final originalPrice = c['originalPrice'] ?? 0;
                    final deposit = c['depositAmount'] ?? 0;
                    final status = c['status']?.toString();
                    return DataRow(
                      onSelectChanged: (_) => _showContractDetailDialog(c),
                      cells: [
                        // B-32: 고객명 + 동/호수 표시
                        DataCell(Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customer?['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500)),
                            if ((c['customerDong'] ?? customer?['dong'] ?? '').toString().isNotEmpty)
                              Text(
                                '${c['customerDong'] ?? customer?['dong'] ?? ''}동 ${c['customerHo'] ?? customer?['ho'] ?? ''}호',
                                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                              ),
                          ],
                        )),
                        DataCell(Text(product?['name'] ?? c['productName'] ?? '-')),
                        DataCell(Text(productItem?['name'] ?? c['productItemName'] ?? '-')),
                        DataCell(Text('${_priceFormat.format(originalPrice)}원', style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text('${_priceFormat.format(deposit)}원', style: const TextStyle(color: AppColors.priceRed, fontWeight: FontWeight.w600))),
                        DataCell(_buildStatusBadge(status)),
                        DataCell(Text(_formatDate(c['createdAt']?.toString()))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 탭 4: 정산관리
  // ═══════════════════════════════════════════
  Widget _buildSettlementsTab() {
    if (_settlements.isEmpty) {
      return const Center(child: Text('정산 내역이 없습니다', style: TextStyle(color: AppColors.textSecondary)));
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.background),
            columnSpacing: 20,
            horizontalMargin: 20,
            columns: const [
              DataColumn(label: Text('고객명', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('상품명', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('결제액', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
              DataColumn(label: Text('수수료', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
              DataColumn(label: Text('지급액', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
              DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('처리', style: TextStyle(fontWeight: FontWeight.w600))),
            ],
            rows: _settlements.map<DataRow>((s) {
              final contract = s['contract'] ?? {};
              final customer = contract['customer'] ?? {};
              final product = contract['product'] ?? {};
              final status = s['status'] ?? 'PENDING';
              final depositAmount = contract['depositAmount'] ?? 0;

              return DataRow(cells: [
                DataCell(Text(customer['name'] ?? '-')),
                DataCell(Text(product['name'] ?? '-')),
                DataCell(Text('${_priceFormat.format(depositAmount)}원')),
                DataCell(Text('${_priceFormat.format(s['fee'] ?? 0)}원', style: TextStyle(color: AppColors.textSecondary))),
                DataCell(Text('${_priceFormat.format(s['amount'] ?? 0)}원', style: const TextStyle(color: AppColors.priceRed, fontWeight: FontWeight.w500))),
                DataCell(_buildSettlementBadge(status)),
                DataCell(_buildSettlementAction(s['id'], status)),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 탭 5: 알림
  // ═══════════════════════════════════════════
  // 전체 읽음 처리
  Future<void> _markAllNotificationsAsRead() async {
    final result = await _notificationService.markAllAsRead();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = {..._notifications[i], 'isRead': true};
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 알림을 읽음으로 표시했습니다')),
      );
    }
  }

  Widget _buildNotificationsTab() {
    if (_notifications.isEmpty) {
      return const Center(child: Text('알림이 없습니다', style: TextStyle(color: AppColors.textSecondary)));
    }

    // 읽지 않은 알림이 있는지 확인
    final hasUnread = _notifications.any((n) => n['isRead'] != true);

    return Column(
      children: [
        // 전체 읽음 버튼
        if (hasUnread)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _markAllNotificationsAsRead,
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('전부 읽음으로 표시', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: _notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = _notifications[index];
              final isRead = n['isRead'] == true;
              return ListTile(
                leading: Icon(
                  isRead ? Icons.notifications_none : Icons.notifications_active,
                  color: isRead ? AppColors.textHint : AppColors.primary,
                ),
                title: Text(n['title'] ?? '', style: TextStyle(
                  fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                  fontSize: 14,
                )),
                subtitle: Text(n['body'] ?? '', style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Text(_formatDate(n['createdAt']?.toString()), style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 계약 상세 다이얼로그 (클릭 시 팝업 + 다운로드)
  // ═══════════════════════════════════════════
  void _showContractDetailDialog(dynamic contractData) {
    final c = contractData as Map<String, dynamic>;
    final customer = c['customer'] as Map<String, dynamic>? ?? {};
    final product = c['product'] as Map<String, dynamic>? ?? {};
    final productItem = c['productItem'] as Map<String, dynamic>? ?? {};
    final originalPrice = c['originalPrice'] ?? 0;
    final deposit = c['depositAmount'] ?? 0;
    final remain = c['remainAmount'] ?? (originalPrice - deposit);
    final status = c['status']?.toString() ?? 'PENDING';
    final depositLabel = status == 'CONFIRMED' || status == 'CANCEL_REQUESTED'
        ? '${_priceFormat.format(deposit)}원 (결제 완료)'
        : '${_priceFormat.format(deposit)}원';

    // 캡처용 키
    final captureKey = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                child: Row(
                  children: [
                    const Text('계약 상세', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // 캡처 대상 영역
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: RepaintBoundary(
                    key: captureKey,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 행사 정보
                          _contractSection('행사 정보', [
                            _contractInfoLine('행사명', _event['title'] ?? '-'),
                            _contractInfoLine('현장명', _event['siteName'] ?? '-'),
                          ]),
                          const SizedBox(height: 16),

                          // 고객 정보
                          _contractSection('고객 정보', [
                            _contractInfoLine('고객명', customer['name'] ?? c['customerName'] ?? '-'),
                            _contractInfoLine('연락처', customer['phone'] ?? c['customerPhone'] ?? '-'),
                          ]),
                          const SizedBox(height: 16),

                          // 업체 정보
                          _contractSection('업체 정보', [
                            _contractInfoLine('업체명', product['vendorName'] ?? c['vendorName'] ?? '-'),
                          ]),
                          const SizedBox(height: 16),

                          // 계약 내용
                          _contractSection('계약 내용', [
                            _contractInfoLine('품목', product['name'] ?? c['productName'] ?? '-'),
                            _contractInfoLine('패키지', productItem['name'] ?? c['productItemName'] ?? '-'),
                          ]),
                          const SizedBox(height: 16),

                          // 계약 금액
                          _contractSection('계약 금액', [
                            _contractPriceLine('가격', '${_priceFormat.format(originalPrice)}원'),
                            _contractPriceLine('계약금', depositLabel, color: AppColors.priceRed),
                            _contractPriceLine('잔금', '${_priceFormat.format(remain)}원'),
                          ]),
                          const SizedBox(height: 16),

                          // 결제 정보 (플레이스홀더)
                          _contractSection('결제 정보', [
                            _contractInfoLine('결제 수단', c['paymentMethod'] ?? '카드결제'),
                            _contractInfoLine('카드/계좌', c['paymentDetail'] ?? '-'),
                            _contractInfoLine('결제일시', c['paidAt'] ?? '-'),
                            // 연동 전 안내
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE0E0E0)),
                                ),
                                child: const Text(
                                  '결제 시스템 연동 후 자동으로 표시됩니다.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // 상태 뱃지
                          Row(
                            children: [
                              const Text('상태: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 계약일
                          Text(
                            '계약일: ${_formatDate(c['createdAt']?.toString())}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(),
              // 하단 다운로드 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadContractAsImage(ctx, captureKey, c),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('계약서 다운로드'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 계약서 이미지 캡처 → 다운로드
  Future<void> _downloadContractAsImage(BuildContext context, GlobalKey key, Map<String, dynamic> contract) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final customerName = (contract['customer'] as Map?)?['name'] ?? '고객';
      final productName = (contract['product'] as Map?)?['name'] ?? '계약';
      final fileName = '계약서_${customerName}_${productName}_${DateTime.now().millisecondsSinceEpoch}.png';

      await downloadImageBytes(bytes, fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계약서가 다운로드되었습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: $e')),
        );
      }
    }
  }

  // 계약 상세 다이얼로그용 섹션 카드
  Widget _contractSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // 계약 상세 다이얼로그용 정보 행
  Widget _contractInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label : $value', style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
    );
  }

  // 계약 상세 다이얼로그용 금액 행
  Widget _contractPriceLine(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: color ?? AppColors.textPrimary, fontWeight: color != null ? FontWeight.w600 : FontWeight.w400)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  // ── 공통 위젯 ──

  Widget _buildStatusBadge(String? status) {
    final text = _getContractStatusText(status);
    final color = _getContractStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildSettlementBadge(String status) {
    const names = {'PENDING': '대기', 'TRANSFERRED': '지급완료', 'COMPLETED': '정산완료'};
    const colors = {'PENDING': Colors.orange, 'TRANSFERRED': Colors.blue, 'COMPLETED': Colors.green};
    final name = names[status] ?? status;
    final color = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }

  // B-30: 정산 액션에 확인 다이얼로그 추가 (돈 관련 실수 방지)
  Widget _buildSettlementAction(String id, String status) {
    if (status == 'PENDING') {
      return TextButton(
        onPressed: () => _confirmSettlementAction(id, '지급', '이 정산 건을 지급 처리하시겠습니까?', () async {
          await _settlementService.transfer(id);
          _loadData();
        }),
        child: const Text('지급', style: TextStyle(color: AppColors.primary)),
      );
    }
    if (status == 'TRANSFERRED') {
      return TextButton(
        onPressed: () => _confirmSettlementAction(id, '완료', '이 정산 건을 완료 처리하시겠습니까?', () async {
          await _settlementService.complete(id);
          _loadData();
        }),
        child: const Text('완료', style: TextStyle(color: Colors.green)),
      );
    }
    return const Text('-', style: TextStyle(color: Colors.grey));
  }

  // B-30: 정산 확인 다이얼로그
  void _confirmSettlementAction(String id, String action, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('정산 $action'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); onConfirm(); },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  String _getContractStatusText(String? status) {
    switch (status) {
      case 'PENDING': return '대기';
      case 'CONFIRMED': return '확정';
      case 'CANCEL_REQUESTED': return '취소요청';
      case 'CANCELLED': return '취소';
      default: return '-';
    }
  }

  Color _getContractStatusColor(String? status) {
    switch (status) {
      case 'PENDING': return AppColors.warning;
      case 'CONFIRMED': return AppColors.success;
      case 'CANCEL_REQUESTED': return AppColors.priceRed;
      case 'CANCELLED': return AppColors.textSecondary;
      default: return AppColors.textHint;
    }
  }
}
