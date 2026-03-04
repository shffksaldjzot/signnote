import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../services/event_service.dart';
import '../../../services/contract_service.dart';

// ============================================
// 대시보드 메인 페이지 (Dashboard)
//
// 구조:
// ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
// | 총 행사수 | | 총 계약수 | | 확정 계약 | | 취소 요청 | | 총 매출   |
// └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘
//
// ┌─ 행사 목록 테이블 ──────────────────────────────┐
// | 행사명 | 현장명 | 세대수 | 참여코드 | 상태       |
// └────────────────────────────────────────────────┘
//
// 데이터: EventService + ContractService로 집계
// ============================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final EventService _eventService = EventService();
  final ContractService _contractService = ContractService();

  bool _isLoading = true;
  List<dynamic> _events = [];          // 행사 목록
  int _totalContracts = 0;             // 총 계약 수
  int _confirmedContracts = 0;         // 확정된 계약 수
  int _cancelRequestedContracts = 0;   // 취소 요청 수
  int _totalRevenue = 0;               // 총 매출 (확정 계약 금액 합계)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 데이터 불러오기 (행사 목록 + 계약 통계)
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 행사 목록 불러오기
    final eventResult = await _eventService.getEvents();

    if (eventResult['success'] == true) {
      final events = eventResult['events'] as List? ?? [];
      _events = events;

      // 각 행사별 계약 데이터를 모아서 통계 계산
      int total = 0;
      int confirmed = 0;
      int cancelRequested = 0;
      int revenue = 0;

      for (final event in events) {
        final eventId = event['id']?.toString() ?? '';
        if (eventId.isEmpty) continue;

        final contractResult = await _contractService.getEventContracts(eventId);
        if (contractResult['success'] == true) {
          final contracts = contractResult['contracts'] as List? ?? [];
          total += contracts.length;

          for (final contract in contracts) {
            final status = contract['status']?.toString() ?? '';
            if (status == 'CONFIRMED') {
              confirmed++;
              // 확정 계약의 총 금액 합산
              final amount = contract['totalAmount'] ?? contract['depositAmount'] ?? 0;
              revenue += (amount is int) ? amount : (amount as num).toInt();
            }
            if (status == 'CANCEL_REQUESTED') cancelRequested++;
          }
        }
      }

      _totalContracts = total;
      _confirmedContracts = confirmed;
      _cancelRequestedContracts = cancelRequested;
      _totalRevenue = revenue;
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 페이지 제목 ──
          const Text(
            '대시보드',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // ── 통계 카드 4개 ──
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    _buildStatCard('총 행사수', '${_events.length}', Icons.event, AppColors.primary),
                    const SizedBox(width: 16),
                    _buildStatCard('총 계약수', '$_totalContracts', Icons.description, AppColors.primaryDark),
                    const SizedBox(width: 16),
                    _buildStatCard('확정 계약', '$_confirmedContracts', Icons.check_circle, AppColors.success),
                    const SizedBox(width: 16),
                    _buildStatCard('취소 요청', '$_cancelRequestedContracts', Icons.cancel, AppColors.priceRed),
                    const SizedBox(width: 16),
                    _buildStatCard('총 매출', '${NumberFormat('#,###', 'ko_KR').format(_totalRevenue)}원', Icons.payments, Colors.purple),
                  ],
                ),

          const SizedBox(height: 32),

          // ── 행사 목록 테이블 ──
          const Text(
            '행사 목록',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // 테이블 영역
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? const Center(
                        child: Text(
                          '등록된 행사가 없습니다',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : AppCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          child: _buildEventsTable(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // 통계 카드 위젯
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 행사 목록 테이블
  Widget _buildEventsTable() {
    final numberFormat = NumberFormat('#,###');

    return DataTable(
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
    );
  }
}
