import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../services/event_service.dart';
import '../../../services/contract_service.dart';

// ============================================
// 전체 계약 현황 페이지 (Contracts Page)
//
// 구조:
// ┌──────────────────────────────────────────┐
// | 계약 현황                 [행사 선택 ▼]   |
// ├──────────────────────────────────────────┤
// | [전체] [대기] [확정] [취소요청] [취소]     |
// ├──────────────────────────────────────────┤
// | 행사명 | 고객명 | 상품명 | 업체명 | 계약금 | 상태 |
// └──────────────────────────────────────────┘
//
// - 행사 드롭다운 필터
// - 상태별 필터 (전체/대기/확정/취소요청/취소)
// ============================================

class ContractsPage extends StatefulWidget {
  const ContractsPage({super.key});

  @override
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> {
  final EventService _eventService = EventService();
  final ContractService _contractService = ContractService();

  bool _isLoading = true;
  List<dynamic> _events = [];           // 행사 목록 (드롭다운용)
  List<dynamic> _allContracts = [];     // 전체 계약 (필터 전)
  String? _selectedEventId;             // 선택된 행사 ID (null = 전체)
  String _selectedStatus = '전체';       // 선택된 상태 필터

  // 상태 필터 옵션
  static const _statusFilters = ['전체', '대기', '확정', '취소요청', '취소'];

  // 상태 한글 ↔ 영문 매핑
  static const _statusMap = {
    '대기': 'PENDING',
    '확정': 'CONFIRMED',
    '취소요청': 'CANCEL_REQUESTED',
    '취소': 'CANCELLED',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 데이터 불러오기
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 행사 목록 불러오기
    final eventResult = await _eventService.getEvents();
    if (eventResult['success'] == true) {
      _events = eventResult['events'] as List? ?? [];
    }

    // 모든 행사의 계약 불러오기
    await _loadContracts();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // 계약 데이터 불러오기 (선택된 행사 기준)
  Future<void> _loadContracts() async {
    List<dynamic> allContracts = [];

    if (_selectedEventId != null) {
      // 특정 행사만
      final result = await _contractService.getEventContracts(_selectedEventId!);
      if (result['success'] == true) {
        final contracts = result['contracts'] as List? ?? [];
        // 각 계약에 행사 정보 추가
        final event = _events.firstWhere(
          (e) => e['id']?.toString() == _selectedEventId,
          orElse: () => {},
        );
        for (final contract in contracts) {
          contract['eventTitle'] = event['title'] ?? '-';
        }
        allContracts = contracts;
      }
    } else {
      // 모든 행사
      for (final event in _events) {
        final eventId = event['id']?.toString() ?? '';
        if (eventId.isEmpty) continue;

        final result = await _contractService.getEventContracts(eventId);
        if (result['success'] == true) {
          final contracts = result['contracts'] as List? ?? [];
          for (final contract in contracts) {
            contract['eventTitle'] = event['title'] ?? '-';
          }
          allContracts.addAll(contracts);
        }
      }
    }

    _allContracts = allContracts;
  }

  // 필터 적용된 계약 목록
  List<dynamic> get _filteredContracts {
    if (_selectedStatus == '전체') return _allContracts;

    final targetStatus = _statusMap[_selectedStatus];
    return _allContracts
        .where((c) => c['status']?.toString() == targetStatus)
        .toList();
  }

  // 계약 상태 한글 변환
  String _getStatusText(String? status) {
    switch (status) {
      case 'PENDING':
        return '대기';
      case 'CONFIRMED':
        return '확정';
      case 'CANCEL_REQUESTED':
        return '취소요청';
      case 'CANCELLED':
        return '취소';
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

  // 행사 드롭다운 변경 시
  Future<void> _onEventChanged(String? eventId) async {
    setState(() {
      _selectedEventId = eventId;
      _isLoading = true;
    });

    await _loadContracts();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final contracts = _filteredContracts;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 상단: 제목 + 행사 드롭다운 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '계약 현황',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              // 행사 선택 드롭다운
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedEventId,
                    hint: const Text('전체 행사'),
                    items: [
                      // "전체 행사" 옵션
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('전체 행사'),
                      ),
                      // 각 행사 옵션
                      ..._events.map((event) {
                        final id = event['id']?.toString() ?? '';
                        return DropdownMenuItem<String?>(
                          value: id,
                          child: Text(event['title'] ?? '-'),
                        );
                      }),
                    ],
                    onChanged: _onEventChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 상태 필터 칩 ──
          Row(
            children: _statusFilters.map((filter) {
              final isActive = _selectedStatus == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isActive,
                  onSelected: (_) {
                    setState(() => _selectedStatus = filter);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isActive ? AppColors.white : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                  checkmarkColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isActive ? AppColors.primary : AppColors.border,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── 계약 테이블 ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : contracts.isEmpty
                    ? const Center(
                        child: Text(
                          '해당 조건에 맞는 계약이 없습니다',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : AppCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(AppColors.background),
                              columnSpacing: 24,
                              horizontalMargin: 20,
                              columns: const [
                                DataColumn(label: Text('행사명', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('고객명', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('상품명', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('업체명', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('계약금', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.w600))),
                              ],
                              rows: contracts.map((contract) {
                                final deposit = contract['depositAmount'] ?? 0;
                                final status = contract['status']?.toString();
                                final statusText = _getStatusText(status);
                                final statusColor = _getStatusColor(status);

                                // 고객/상품/업체 정보
                                final customer = contract['customer'] as Map<String, dynamic>?;
                                final product = contract['product'] as Map<String, dynamic>?;

                                return DataRow(cells: [
                                  DataCell(Text(contract['eventTitle'] ?? '-')),
                                  DataCell(Text(customer?['name'] ?? '-')),
                                  DataCell(Text(product?['name'] ?? '-')),
                                  DataCell(Text(product?['vendorName'] ?? '-')),
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
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
