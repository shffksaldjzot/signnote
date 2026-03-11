import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../services/event_service.dart';
import '../event_form_screen.dart';

// ============================================
// 행사 관리 페이지 (Events Page) - 관리자 웹 대시보드용
//
// 구조:
// ┌──────────────────────────────────────────────────┐
// | 행사 관리                           [+ 행사 등록]  |
// | [검색바]                          [정렬 드롭다운]  |
// ├──────────────────────────────────────────────────┤
// | 행사명 | 주관사 | 현장명 | 세대수 | 참여코드 | 상태 |
// └──────────────────────────────────────────────────┘
// ============================================

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final EventService _eventService = EventService();
  bool _isLoading = true;
  List<dynamic> _events = [];           // 원본 행사 목록
  List<dynamic> _filteredEvents = [];   // 검색/정렬 적용된 목록

  // 검색어
  final TextEditingController _searchController = TextEditingController();
  // 정렬 기준
  String _sortBy = 'newest';

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

  // 행사 목록 불러오기
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    final result = await _eventService.getEvents();
    if (result['success'] == true) {
      _events = result['events'] as List? ?? [];
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _applyFilter(); // 검색/정렬 적용
    }
  }

  // 검색어와 정렬 기준으로 목록 필터링
  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    // 검색: 행사명, 주관사명, 현장명에 검색어 포함
    List<dynamic> result = _events.where((e) {
      if (query.isEmpty) return true;
      final title = (e['title'] ?? '').toString().toLowerCase();
      final organizer = (e['organizer']?['name'] ?? '').toString().toLowerCase();
      final siteName = (e['siteName'] ?? '').toString().toLowerCase();
      return title.contains(query) || organizer.contains(query) || siteName.contains(query);
    }).toList();

    // 정렬
    result.sort((a, b) {
      switch (_sortBy) {
        case 'oldest': // 오래된순
          final aDate = a['startDate']?.toString() ?? '';
          final bDate = b['startDate']?.toString() ?? '';
          return aDate.compareTo(bDate);
        case 'name': // 이름순 (가나다)
          return (a['title'] ?? '').compareTo(b['title'] ?? '');
        case 'organizer': // 주관사순 (가나다)
          final aOrg = (a['organizer']?['name'] ?? '').toString();
          final bOrg = (b['organizer']?['name'] ?? '').toString();
          return aOrg.compareTo(bOrg);
        case 'newest': // 최신순 (기본)
        default:
          final aDate = a['startDate']?.toString() ?? '';
          final bDate = b['startDate']?.toString() ?? '';
          return bDate.compareTo(aDate);
      }
    });

    setState(() {
      _filteredEvents = result;
    });
  }

  // 행사 상태 텍스트 계산 (소프트 삭제 포함)
  String _getEventStatus(Map<String, dynamic> event) {
    // 소프트 삭제된 행사
    if (event['deletedAt'] != null) return '삭제됨';

    try {
      final now = DateTime.now();
      final startStr = event['startDate']?.toString();
      final endStr = event['endDate']?.toString();

      if (startStr == null || endStr == null) return '미정';

      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);

      if (now.isBefore(start)) return '예정';
      if (now.isAfter(end)) return '종료';
      return '진행중';
    } catch (_) {
      return '미정';
    }
  }

  // 상태별 색상
  Color _getStatusColor(String status) {
    switch (status) {
      case '진행중':
        return AppColors.success;
      case '예정':
        return AppColors.primary;
      case '종료':
        return AppColors.textSecondary;
      case '삭제됨':
        return AppColors.priceRed;
      default:
        return AppColors.textHint;
    }
  }

  // "행사 등록" 버튼 → 다이얼로그로 폼 표시
  void _showEventFormDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 600,
          height: 700,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scaffold(
              // 기존 OrganizerEventFormScreen을 다이얼로그 안에서 재사용
              body: Stack(
                children: [
                  const OrganizerEventFormScreen(),
                  // 닫기 버튼
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((result) {
      // 다이얼로그에서 돌아온 후 목록 새로고침
      if (result == true) {
        _loadEvents();
      }
    });
  }

  // ---- 행사 삭제 확인 다이얼로그 (관리자용) ----
  void _confirmDeleteEvent(dynamic event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('행사 삭제'),
        content: Text(
          '\'${event['title']}\' 행사를 삭제하시겠습니까?\n\n'
          '삭제하면 관련된 모든 데이터가 삭제되며 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _executeDeleteEvent(event);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 행사 삭제 API 호출
  Future<void> _executeDeleteEvent(dynamic event) async {
    final eventId = event['id']?.toString() ?? '';
    if (eventId.isEmpty) return;

    final result = await _eventService.deleteEvent(eventId);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\'${event['title']}\' 행사가 삭제되었습니다')),
      );
      _loadEvents(); // 목록 새로고침
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '행사 삭제에 실패했습니다')),
      );
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
          // ── 상단: 제목 + 행사 등록 버튼 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '행사 관리',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showEventFormDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('행사 등록'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 검색바 + 정렬 드롭다운 ──
          Row(
            children: [
              // 검색바 (행사명/주관사명/현장명 검색)
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
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 정렬 드롭다운
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
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
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                        _applyFilter();
                      }
                    },
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
                              _searchController.text.isNotEmpty
                                  ? '검색 결과가 없습니다'
                                  : '등록된 행사가 없습니다',
                              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),
                            if (_searchController.text.isEmpty)
                              // 화면 중앙에 큰 행사 등록 버튼
                              ElevatedButton.icon(
                                onPressed: _showEventFormDialog,
                                icon: const Icon(Icons.add, size: 24),
                                label: const Text('행사 등록하기', style: TextStyle(fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                          ],
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
                                // 주관사 컬럼 추가 (행사명과 현장명 사이)
                                DataColumn(label: Text('주관사', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('현장명', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('세대수', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('참여코드', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('관리', style: TextStyle(fontWeight: FontWeight.w600))),
                              ],
                              rows: _filteredEvents.map((event) {
                                final status = _getEventStatus(event);
                                final unitCount = event['unitCount'] ?? 0;
                                // 주관사명 가져오기 (API 응답의 organizer.name)
                                final organizerName = event['organizer']?['name'] ?? '-';

                                return DataRow(
                                  cells: [
                                    // 행사명 — 클릭 시 상세 이동 + 말줄임 + 삭제 배지
                                    DataCell(
                                      Tooltip(
                                        message: event['title'] ?? '-',
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 220),
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
                                              // 소프트 삭제 배지
                                              if (event['deletedAt'] != null) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.priceRed.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    '주관사가 삭제함',
                                                    style: TextStyle(fontSize: 10, color: AppColors.priceRed, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        final eventId = event['id']?.toString() ?? '';
                                        context.go('/admin/events/$eventId');
                                      },
                                    ),
                                    // 주관사명 셀
                                    DataCell(Text(organizerName)),
                                    // 현장명 — 최대 너비 제한 + 말줄임 + 툴팁
                                    DataCell(Tooltip(
                                      message: event['siteName'] ?? '-',
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 160),
                                        child: Text(
                                          event['siteName'] ?? '-',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )),
                                    DataCell(Text(unitCount > 0 ? numberFormat.format(unitCount) : '-')),
                                    DataCell(Text(
                                      event['entryCode'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2,
                                      ),
                                    )),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 관리 (삭제) 버튼
                                    DataCell(IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      tooltip: '행사 삭제',
                                      onPressed: () => _confirmDeleteEvent(event),
                                    )),
                                  ],
                                );
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
