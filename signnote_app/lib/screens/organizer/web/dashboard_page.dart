import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../services/event_service.dart';
import '../../../services/contract_service.dart';
import '../../../services/user_service.dart';
import '../../../services/settlement_service.dart';

// ============================================
// 대시보드 메인 페이지 (Dashboard) — 통계 요약
//
// 구조:
// ┌─ 필터 바 ─────────────────────────────────┐
// | [오늘] [1주] [1개월] [3개월]  주관사▼  행사▼ |
// └───────────────────────────────────────────┘
// ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
// │ 행사    │ │ 업체   │ │ 계약    │ │ 매출   │
// └────────┘ └────────┘ └────────┘ └────────┘
// ┌─ 최근 행사 ──────┐ ┌─ 최근 계약 ──────────┐
// └─────────────────┘ └─────────────────────┘
// ============================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final EventService _eventService = EventService();
  final ContractService _contractService = ContractService();
  final UserService _userService = UserService();
  final SettlementService _settlementService = SettlementService();
  final _priceFormat = NumberFormat('#,###', 'ko_KR');

  bool _isLoading = true;

  // --- 원본 데이터 ---
  List<Map<String, dynamic>> _events = [];
  List<dynamic> _allContracts = [];
  List<dynamic> _vendors = [];
  List<dynamic> _organizers = [];
  List<dynamic> _settlements = [];

  // --- 필터 상태 ---
  String _periodFilter = '전체';  // 오늘 / 1주 / 1개월 / 3개월 / 전체
  String? _organizerFilter;       // 주관사 ID
  String? _eventFilter;           // 행사 ID

  static const _periodOptions = ['오늘', '1주', '1개월', '3개월', '전체'];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // 모든 데이터 불러오기
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    // 행사 목록
    final eventResult = await _eventService.getEvents();
    if (eventResult['success'] == true) {
      final List rawEvents = eventResult['events'] ?? [];
      _events = rawEvents.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    }

    // 업체 목록 (VENDOR)
    final vendorResult = await _userService.getUsers(role: 'VENDOR');
    if (vendorResult['success'] == true) {
      _vendors = vendorResult['users'] ?? [];
    }

    // 주관사 목록 (ORGANIZER)
    final orgResult = await _userService.getUsers(role: 'ORGANIZER');
    if (orgResult['success'] == true) {
      _organizers = orgResult['users'] ?? [];
    }

    // 모든 행사의 계약 수집
    _allContracts = [];
    for (final event in _events) {
      final eventId = event['id']?.toString() ?? '';
      if (eventId.isEmpty) continue;
      final result = await _contractService.getEventContracts(eventId);
      if (result['success'] == true) {
        final contracts = result['contracts'] as List? ?? [];
        for (final c in contracts) {
          c['eventId'] = eventId;
          c['eventTitle'] = event['title'] ?? '-';
        }
        _allContracts.addAll(contracts);
      }
    }

    // 정산 목록
    final settleResult = await _settlementService.getAllSettlements();
    if (settleResult['success'] == true) {
      _settlements = settleResult['settlements'] ?? [];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // --- 필터링 로직 ---

  // 기간 필터 시작일 계산
  DateTime? get _periodStartDate {
    final now = DateTime.now();
    switch (_periodFilter) {
      case '오늘':
        return DateTime(now.year, now.month, now.day);
      case '1주':
        return now.subtract(const Duration(days: 7));
      case '1개월':
        return DateTime(now.year, now.month - 1, now.day);
      case '3개월':
        return DateTime(now.year, now.month - 3, now.day);
      default:
        return null; // 전체
    }
  }

  // 주관사 필터 적용된 행사 목록
  List<Map<String, dynamic>> get _filteredEvents {
    var result = _events.toList();
    // 주관사 필터
    if (_organizerFilter != null) {
      result = result.where((e) =>
        e['organizerId']?.toString() == _organizerFilter ||
        e['organizer']?['id']?.toString() == _organizerFilter
      ).toList();
    }
    // 행사 필터
    if (_eventFilter != null) {
      result = result.where((e) => e['id']?.toString() == _eventFilter).toList();
    }
    return result;
  }

  // 필터 적용된 계약 목록
  List<dynamic> get _filteredContracts {
    final eventIds = _filteredEvents.map((e) => e['id']?.toString()).toSet();
    var result = _allContracts.where((c) => eventIds.contains(c['eventId']?.toString())).toList();

    // 기간 필터
    final startDate = _periodStartDate;
    if (startDate != null) {
      result = result.where((c) {
        final dateStr = c['createdAt']?.toString();
        if (dateStr == null) return false;
        try {
          return DateTime.parse(dateStr).isAfter(startDate);
        } catch (_) {
          return false;
        }
      }).toList();
    }
    return result;
  }

  // --- 통계 계산 ---

  // 행사 통계
  int get _activeEventCount => _filteredEvents.where((e) {
    try {
      final now = DateTime.now();
      final start = DateTime.parse(e['startDate'].toString());
      final end = DateTime.parse(e['endDate'].toString());
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) { return false; }
  }).length;

  // 계약 통계
  int get _confirmedContractCount => _filteredContracts
      .where((c) => c['status'] == 'CONFIRMED').length;

  // 매출 (확정 계약의 계약금 합계)
  int get _totalRevenue => _filteredContracts
      .where((c) => c['status'] == 'CONFIRMED')
      .fold<int>(0, (sum, c) => sum + ((c['depositAmount'] ?? 0) as int));

  // 미승인 업체 수
  int get _pendingVendorCount => _vendors
      .where((v) => v['isApproved'] != true).length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final contracts = _filteredContracts;
    // 최근 계약 5건
    final recentContracts = List.from(contracts);
    recentContracts.sort((a, b) =>
      (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
    final topContracts = recentContracts.take(5).toList();

    // 최근 행사 5건
    final recentEvents = List<Map<String, dynamic>>.from(_filteredEvents);
    recentEvents.sort((a, b) =>
      (b['startDate'] ?? '').compareTo(a['startDate'] ?? ''));
    final topEvents = recentEvents.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 페이지 제목 ──
          const Text('대시보드', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          // ── 필터 바 ──
          _buildFilterBar(),
          const SizedBox(height: 24),

          // ── 통계 카드 4개 ──
          Row(
            children: [
              _buildStatCard('행사', '${_filteredEvents.length}개', '진행중 $_activeEventCount', Icons.event, AppColors.primary),
              const SizedBox(width: 16),
              _buildStatCard('업체', '${_vendors.length}개', '미승인 $_pendingVendorCount', Icons.business, AppColors.organizer),
              const SizedBox(width: 16),
              _buildStatCard('계약', '${contracts.length}건', '확정 $_confirmedContractCount', Icons.description, AppColors.success),
              const SizedBox(width: 16),
              _buildStatCard('매출', '${_priceFormat.format(_totalRevenue)}원', '계약금 기준', Icons.account_balance_wallet, AppColors.priceRed),
            ],
          ),
          const SizedBox(height: 24),

          // ── 최근 행사 + 최근 계약 (2열) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 최근 행사
              Expanded(child: _buildRecentEventsCard(topEvents)),
              const SizedBox(width: 16),
              // 최근 계약
              Expanded(child: _buildRecentContractsCard(topContracts)),
            ],
          ),
        ],
      ),
    );
  }

  // ── 필터 바 ──
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 기간 필터 칩
          ..._periodOptions.map((option) {
            final isSelected = _periodFilter == option;
            return InkWell(
              onTap: () => setState(() => _periodFilter = option),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 8),

          // 주관사 필터 드롭다운
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _organizerFilter,
                hint: const Text('전체 주관사', style: TextStyle(fontSize: 13)),
                isDense: true,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                items: [
                  const DropdownMenuItem(value: null, child: Text('전체 주관사')),
                  ..._organizers.map((o) => DropdownMenuItem(
                    value: o['id']?.toString(),
                    child: Text(o['name'] ?? '-', overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: (value) => setState(() {
                  _organizerFilter = value;
                  _eventFilter = null; // 주관사 변경 시 행사 필터 초기화
                }),
              ),
            ),
          ),

          // 행사 필터 드롭다운
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _eventFilter,
                hint: const Text('전체 행사', style: TextStyle(fontSize: 13)),
                isDense: true,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                items: [
                  const DropdownMenuItem(value: null, child: Text('전체 행사')),
                  // 주관사 필터가 있으면 해당 주관사의 행사만 표시
                  ...(_organizerFilter != null
                    ? _events.where((e) =>
                        e['organizerId']?.toString() == _organizerFilter ||
                        e['organizer']?['id']?.toString() == _organizerFilter)
                    : _events
                  ).map((e) => DropdownMenuItem(
                    value: e['id']?.toString(),
                    child: Text(e['title'] ?? '-', overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: (value) => setState(() => _eventFilter = value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 통계 카드 ──
  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 최근 행사 카드 ──
  Widget _buildRecentEventsCard(List<Map<String, dynamic>> events) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('최근 행사', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => context.go(AppRoutes.organizerWebEvents),
                child: const Text('전체보기', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('행사가 없습니다', style: TextStyle(color: AppColors.textHint))),
            )
          else
            ...events.map((event) {
              final status = _getEventStatus(event);
              final statusColor = _getStatusColor(status);
              final organizerName = event['organizer']?['name'] ?? '-';
              return InkWell(
                onTap: () => context.go('/admin/events/${event['id']}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      // 상태 뱃지
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(event['title'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      Text(organizerName, style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── 최근 계약 카드 ──
  Widget _buildRecentContractsCard(List<dynamic> contracts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('최근 계약', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (contracts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('계약이 없습니다', style: TextStyle(color: AppColors.textHint))),
            )
          else
            ...contracts.map((c) {
              final customer = c['customer'] as Map<String, dynamic>?;
              final product = c['product'] as Map<String, dynamic>?;
              final deposit = c['depositAmount'] ?? 0;
              final status = c['status']?.toString();
              final statusText = _getContractStatusText(status);
              final statusColor = _getContractStatusColor(status);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    // 상태 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(customer?['name'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    Text(product?['name'] ?? '-', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    Text('${_priceFormat.format(deposit)}원', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.priceRed)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 행사 상태 텍스트
  String _getEventStatus(Map<String, dynamic> event) {
    try {
      final now = DateTime.now();
      final start = DateTime.parse(event['startDate'].toString());
      final end = DateTime.parse(event['endDate'].toString());
      if (now.isBefore(start)) return '예정';
      if (now.isAfter(end)) return '종료';
      return '진행중';
    } catch (_) { return '미정'; }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '진행중': return AppColors.success;
      case '예정': return AppColors.primary;
      case '종료': return AppColors.textSecondary;
      default: return AppColors.textHint;
    }
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
