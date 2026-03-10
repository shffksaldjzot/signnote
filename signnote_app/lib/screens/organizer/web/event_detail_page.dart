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
import '../../../services/settlement_service.dart';
import '../../../services/notification_service.dart';
import '../event_form_screen.dart';

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
    _tabController = TabController(length: 5, vsync: this);
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
                icon: const Icon(Icons.edit, size: 16),
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

          // ── 행사 기본 정보 바 ──
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  // 고객 코드
                  _buildInfoChip('고객코드', customerCode, () => _copyCode(customerCode, '고객코드')),
                  // 업체 코드
                  _buildInfoChip('업체코드', vendorCode, () => _copyCode(vendorCode, '업체코드')),
                  // 기간
                  Text(
                    '기간: ${_formatDate(_event['startDate']?.toString())} ~ ${_formatDate(_event['endDate']?.toString())}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  // 세대수
                  Text(
                    '세대수: ${_priceFormat.format(_event['unitCount'] ?? 0)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  // 주관사
                  Text(
                    '주관사: ${_event['organizer']?['name'] ?? '-'}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  // 계약금 비율
                  Text(
                    '계약금: ${((_event['depositRate'] ?? 0.3) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // ── 5개 탭 ──
          AppCard(
            padding: EdgeInsets.zero,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: [
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

  // 정보 칩 (코드 + 복사)
  Widget _buildInfoChip(String label, String value, VoidCallback onCopy) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.primary)),
        const SizedBox(width: 4),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onCopy,
          child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.copy, size: 14, color: AppColors.textHint)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 탭 1: 품목관리 — 클릭하면 3뎁스로 드릴다운
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
  Widget _buildContractsTab() {
    if (_contracts.isEmpty) {
      return const Center(child: Text('계약 내역이 없습니다', style: TextStyle(color: AppColors.textSecondary)));
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
            columns: [
              const DataColumn(label: Text('고객명', style: TextStyle(fontWeight: FontWeight.w600))),
              const DataColumn(label: Text('품목', style: TextStyle(fontWeight: FontWeight.w600))),
              const DataColumn(label: Text('패키지', style: TextStyle(fontWeight: FontWeight.w600))),
              const DataColumn(label: Text('업체', style: TextStyle(fontWeight: FontWeight.w600))),
              const DataColumn(label: Text('총 금액', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text(
                '계약금 (${((_event['depositRate'] ?? 0.3) * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
              const DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.w600))),
              const DataColumn(label: Text('날짜', style: TextStyle(fontWeight: FontWeight.w600))),
            ],
            rows: _contracts.map((c) {
              final customer = c['customer'] as Map<String, dynamic>?;
              final product = c['product'] as Map<String, dynamic>?;
              final productItem = c['productItem'] as Map<String, dynamic>?;
              final originalPrice = c['originalPrice'] ?? 0;
              final deposit = c['depositAmount'] ?? 0;
              final status = c['status']?.toString();
              return DataRow(cells: [
                DataCell(Text(customer?['name'] ?? '-')),
                DataCell(Text(product?['name'] ?? c['productName'] ?? '-')),
                DataCell(Text(productItem?['name'] ?? c['productItemName'] ?? '-')),
                DataCell(Text(product?['vendorName'] ?? c['vendorName'] ?? '-')),
                DataCell(Text('${_priceFormat.format(originalPrice)}원', style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text('${_priceFormat.format(deposit)}원', style: const TextStyle(color: AppColors.priceRed, fontWeight: FontWeight.w600))),
                DataCell(_buildStatusBadge(status)),
                DataCell(Text(_formatDate(c['createdAt']?.toString()))),
              ]);
            }).toList(),
          ),
        ),
      ),
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

  Widget _buildSettlementAction(String id, String status) {
    if (status == 'PENDING') {
      return TextButton(
        onPressed: () async {
          await _settlementService.transfer(id);
          _loadData();
        },
        child: const Text('지급', style: TextStyle(color: AppColors.primary)),
      );
    }
    if (status == 'TRANSFERRED') {
      return TextButton(
        onPressed: () async {
          await _settlementService.complete(id);
          _loadData();
        },
        child: const Text('완료', style: TextStyle(color: Colors.green)),
      );
    }
    return const Text('-', style: TextStyle(color: Colors.grey));
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
