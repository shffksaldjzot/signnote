import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../services/event_service.dart';
import '../event_form_screen.dart';

// ============================================
// 행사 관리 페이지 (Events Page)
//
// 구조:
// ┌──────────────────────────────────────────┐
// | 행사 관리                  [+ 행사 등록]  |
// ├──────────────────────────────────────────┤
// | 행사명 | 현장명 | 세대수 | 참여코드 | 상태 |
// | 창원 자이 | 창원자이 | 500 | 123456 | 진행중|
// └──────────────────────────────────────────┘
//
// "행사 등록" 클릭 → OrganizerEventFormScreen을 다이얼로그로 표시
// 행사 클릭 → 행사 상세로 이동
// ============================================

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final EventService _eventService = EventService();
  bool _isLoading = true;
  List<dynamic> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
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
    }
  }

  // 행사 상태 텍스트 계산
  String _getEventStatus(Map<String, dynamic> event) {
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
          const SizedBox(height: 24),

          // ── 행사 테이블 ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_note, size: 64, color: AppColors.textHint),
                            const SizedBox(height: 16),
                            const Text(
                              '등록된 행사가 없습니다',
                              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),
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
                                DataColumn(label: Text('현장명', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('세대수', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('참여코드', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.w600))),
                              ],
                              rows: _events.map((event) {
                                final status = _getEventStatus(event);
                                final unitCount = event['unitCount'] ?? 0;

                                return DataRow(
                                  // 행사 클릭 → 행사 상세로 이동
                                  onSelectChanged: (_) {
                                    final eventId = event['id']?.toString() ?? '';
                                    context.go('/organizer/events/$eventId');
                                  },
                                  cells: [
                                    DataCell(Text(event['title'] ?? '-')),
                                    DataCell(Text(event['siteName'] ?? '-')),
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
