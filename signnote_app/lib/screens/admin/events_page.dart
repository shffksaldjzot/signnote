import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../widgets/common/app_card.dart';
import '../../services/event_service.dart';
import '../../services/contract_service.dart';
import '../organizer/event_form_screen.dart';

// ============================================
// 행사 관리 페이지 (Events Page)
//
// 개선 사항:
// - B-14: 상태별 필터 탭 (전체/진행중/예정/종료)
// - B-15: 핵심 숫자 컬럼 (계약 수, 매출)
// - B-18: 참여코드 고객/업체 구분
// - B-40: 테이블 행 높이 조정
// - B-43: 아이패드 반응형 패딩
// ============================================

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final EventService _eventService = EventService();
  final ContractService _contractService = ContractService();
  bool _isLoading = true;
  List<dynamic> _events = [];
  List<dynamic> _filteredEvents = [];

  // 검색어
  final TextEditingController _searchController = TextEditingController();
  // 정렬
  String _sortBy = 'newest';
  // B-14: 상태 필터
  String _statusFilter = '전체';

  // B-15: 행사별 계약 수/매출 캐시
  Map<String, int> _contractCounts = {};
  Map<String, int> _revenueCounts = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 행사 목록 + 계약 집계 불러오기
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    final result = await _eventService.getEvents();
    if (result['success'] == true) {
      _events = result['events'] as List? ?? [];
    }

    // B-15: 행사별 계약 수/매출 집계
    _contractCounts = {};
    _revenueCounts = {};
    for (final event in _events) {
      final eventId = event['id']?.toString() ?? '';
      if (eventId.isEmpty) continue;
      final contractResult = await _contractService.getEventContracts(eventId);
      if (contractResult['success'] == true) {
        final contracts = contractResult['contracts'] as List? ?? [];
        final confirmed = contracts.where((c) => c['status'] == 'CONFIRMED');
        _contractCounts[eventId] = confirmed.length;
        _revenueCounts[eventId] = confirmed.fold<int>(
          0, (sum, c) => sum + ((c['depositAmount'] ?? 0) as int));
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _applyFilter();
    }
  }

  // 필터/검색/정렬 적용
  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    List<dynamic> result = _events.where((e) {
      // 검색 필터
      if (query.isNotEmpty) {
        final title = (e['title'] ?? '').toString().toLowerCase();
        final organizer = (e['organizer']?['name'] ?? '').toString().toLowerCase();
        final siteName = (e['siteName'] ?? '').toString().toLowerCase();
        if (!title.contains(query) && !organizer.contains(query) && !siteName.contains(query)) {
          return false;
        }
      }
      // B-14: 상태 필터
      if (_statusFilter != '전체') {
        final status = _getEventStatus(e);
        if (status != _statusFilter) return false;
      }
      return true;
    }).toList();

    // 정렬
    result.sort((a, b) {
      switch (_sortBy) {
        case 'oldest':
          return (a['startDate']?.toString() ?? '').compareTo(b['startDate']?.toString() ?? '');
        case 'name':
          return (a['title'] ?? '').compareTo(b['title'] ?? '');
        case 'organizer':
          return (a['organizer']?['name'] ?? '').toString().compareTo((b['organizer']?['name'] ?? '').toString());
        case 'newest':
        default:
          return (b['startDate']?.toString() ?? '').compareTo(a['startDate']?.toString() ?? '');
      }
    });

    setState(() => _filteredEvents = result);
  }

  // 행사 상태 계산
  String _getEventStatus(dynamic event) {
    if (event['deletedAt'] != null) return '삭제됨';
    try {
      final now = DateTime.now();
      final start = DateTime.parse(event['startDate']?.toString() ?? '');
      final end = DateTime.parse(event['endDate']?.toString() ?? '');
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
      case '삭제됨': return AppColors.priceRed;
      default: return AppColors.textHint;
    }
  }

  // B-14: 상태별 카운트
  int _countByStatus(String status) {
    if (status == '전체') return _events.length;
    return _events.where((e) => _getEventStatus(e) == status).length;
  }

  // "행사 등록" 다이얼로그
  void _showEventFormDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 600, height: 700,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scaffold(
              body: Stack(
                children: [
                  const OrganizerEventFormScreen(),
                  Positioned(
                    top: 8, right: 8,
                    child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((result) {
      if (result == true) _loadEvents();
    });
  }

  // 행사 삭제
  void _confirmDeleteEvent(dynamic event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('행사 삭제'),
        content: Text('\'${event['title']}\' 행사를 삭제하시겠습니까?\n\n삭제하면 관련된 모든 데이터가 삭제되며 복구할 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () { Navigator.pop(context); _executeDeleteEvent(event); },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDeleteEvent(dynamic event) async {
    final eventId = event['id']?.toString() ?? '';
    if (eventId.isEmpty) return;
    final result = await _eventService.deleteEvent(eventId);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\'${event['title']}\' 행사가 삭제되었습니다')));
      _loadEvents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? '행사 삭제에 실패했습니다')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    // B-43: 반응형 패딩
    final isCompact = MediaQuery.of(context).size.width < 1024;
    final padding = isCompact ? 20.0 : 32.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 제목 + 행사 등록 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('행사 관리', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              ElevatedButton.icon(
                onPressed: _showEventFormDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('행사 등록'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── B-14: 상태별 필터 탭 ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['전체', '진행중', '예정', '종료'].map((status) {
              final isSelected = _statusFilter == status;
              final count = _countByStatus(status);
              return InkWell(
                onTap: () { setState(() => _statusFilter = status); _applyFilter(); },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(
                    '$status ($count)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // ── 검색바 + 정렬 ──
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilter(),
                    decoration: InputDecoration(
                      hintText: '행사명, 주관사, 현장명 검색',
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textHint),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    icon: const Icon(Icons.sort, size: 18, color: AppColors.textSecondary),
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('최신순')),
                      DropdownMenuItem(value: 'oldest', child: Text('오래된순')),
                      DropdownMenuItem(value: 'name', child: Text('이름순')),
                      DropdownMenuItem(value: 'organizer', child: Text('주관사순')),
                    ],
                    onChanged: (value) { if (value != null) { setState(() => _sortBy = value); _applyFilter(); } },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 행사 테이블 ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_note, size: 64, color: AppColors.textHint),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty || _statusFilter != '전체'
                                  ? '검색 결과가 없습니다' : '등록된 행사가 없습니다',
                              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                            ),
                            if (_searchController.text.isEmpty && _statusFilter == '전체') ...[
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _showEventFormDialog,
                                icon: const Icon(Icons.add, size: 24),
                                label: const Text('행사 등록하기', style: TextStyle(fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : AppCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - (isCompact ? 108 : 304)),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(AppColors.background),
                              // B-40: 행 높이 조정
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 64,
                              columnSpacing: 20,
                              horizontalMargin: 20,
                              columns: [
                                const DataColumn(label: Text('행사명', style: TextStyle(fontWeight: FontWeight.w600))),
                                const DataColumn(label: Text('주관사', style: TextStyle(fontWeight: FontWeight.w600))),
                                const DataColumn(label: Text('현장명', style: TextStyle(fontWeight: FontWeight.w600))),
                                // B-18: 고객코드 / 업체코드 분리
                                const DataColumn(label: Text('고객코드', style: TextStyle(fontWeight: FontWeight.w600))),
                                if (!isCompact)
                                  const DataColumn(label: Text('업체코드', style: TextStyle(fontWeight: FontWeight.w600))),
                                // B-15: 계약 수 / 매출
                                const DataColumn(label: Text('계약', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                                if (!isCompact)
                                  const DataColumn(label: Text('매출', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                                const DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.w600))),
                                const DataColumn(label: Text('관리', style: TextStyle(fontWeight: FontWeight.w600))),
                              ],
                              rows: _filteredEvents.map((event) {
                                final status = _getEventStatus(event);
                                final organizerName = event['organizer']?['name'] ?? '-';
                                final eventId = event['id']?.toString() ?? '';
                                final contractCount = _contractCounts[eventId] ?? 0;
                                final revenue = _revenueCounts[eventId] ?? 0;

                                return DataRow(cells: [
                                  // 행사명 (클릭 이동)
                                  DataCell(
                                    Tooltip(
                                      message: event['title'] ?? '-',
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 200),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                event['title'] ?? '-',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: event['deletedAt'] != null ? AppColors.textHint : AppColors.primary,
                                                  fontWeight: FontWeight.w500,
                                                  decoration: event['deletedAt'] != null ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                            ),
                                            if (event['deletedAt'] != null) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.priceRed.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('삭제됨', style: TextStyle(fontSize: 10, color: AppColors.priceRed, fontWeight: FontWeight.w600)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    onTap: () => context.go('/admin/events/$eventId'),
                                  ),
                                  // 주관사
                                  DataCell(Text(organizerName)),
                                  // 현장명
                                  DataCell(Tooltip(
                                    message: event['siteName'] ?? '-',
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 140),
                                      child: Text(event['siteName'] ?? '-', overflow: TextOverflow.ellipsis),
                                    ),
                                  )),
                                  // B-18: 고객코드
                                  DataCell(Text(
                                    event['entryCode'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 2, fontSize: 13),
                                  )),
                                  // B-18: 업체코드 (PC에서만)
                                  if (!isCompact)
                                    DataCell(Text(
                                      event['vendorEntryCode'] ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 2, fontSize: 13, color: AppColors.organizer),
                                    )),
                                  // B-15: 계약 수
                                  DataCell(Text(
                                    contractCount > 0 ? '$contractCount건' : '-',
                                    style: TextStyle(
                                      fontWeight: contractCount > 0 ? FontWeight.w600 : FontWeight.w400,
                                      color: contractCount > 0 ? AppColors.textPrimary : AppColors.textHint,
                                    ),
                                  )),
                                  // B-15: 매출 (PC에서만)
                                  if (!isCompact)
                                    DataCell(Text(
                                      revenue > 0 ? '${numberFormat.format(revenue)}원' : '-',
                                      style: TextStyle(
                                        fontWeight: revenue > 0 ? FontWeight.w600 : FontWeight.w400,
                                        color: revenue > 0 ? AppColors.priceRed : AppColors.textHint,
                                      ),
                                    )),
                                  // 상태
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getStatusColor(status))),
                                  )),
                                  // 관리
                                  DataCell(IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    tooltip: '행사 삭제',
                                    onPressed: () => _confirmDeleteEvent(event),
                                  )),
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
