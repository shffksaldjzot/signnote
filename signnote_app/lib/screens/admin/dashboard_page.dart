import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/event_service.dart';
import '../../services/contract_service.dart';
import '../../services/user_service.dart';
import '../../services/settlement_service.dart';
import '../../services/activity_log_service.dart';
import '../../utils/number_formatter.dart';

// ============================================
// 스마트 대시보드 — 완전 재설계
//
// E-1: 처리 필요 인라인 액션 (승인/거부 바로 처리)
// E-2: 행사 현황 보드 (칸반형 카드, 모든 숫자 클릭→이동)
// E-3: 계약 파이프라인 (상태별 막대, 클릭→필터)
// E-4: 인기 품목/업체 성과 (탭 전환, 클릭→상세)
// E-5: 실시간 활동 피드 (타임라인, 딥링크)
// E-6: 슬라이드 패널 (페이지 이동 없는 상세보기)
//
// 원칙: 모든 숫자는 클릭 가능, 3번 이상 클릭 없음
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
  // ignore: unused_field — 추후 정산 탭 연동용
  final SettlementService _settlementService = SettlementService();
  final ActivityLogService _logService = ActivityLogService();
  final _fmt = NumberFormat('#,###', 'ko_KR');

  bool _isLoading = true;

  // 원본 데이터
  List<Map<String, dynamic>> _events = [];
  List<dynamic> _allContracts = [];
  List<dynamic> _vendors = [];
  List<dynamic> _logs = [];
  // userId → 이름 매핑
  final Map<String, String> _userNames = {};

  // E-4: 탭 상태 (인기 품목 vs 업체 성과)
  bool _showVendorPerf = false;

  // E-6: 슬라이드 패널
  Widget? _slidePanel;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // 전체 데이터 로드
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    // 행사
    final eventResult = await _eventService.getEvents();
    if (eventResult['success'] == true) {
      _events = (eventResult['events'] as List? ?? [])
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    }

    // 업체 (VENDOR)
    final vendorResult = await _userService.getUsers(role: 'VENDOR');
    if (vendorResult['success'] == true) {
      _vendors = vendorResult['users'] ?? [];
      for (final v in _vendors) {
        final id = v['id']?.toString() ?? '';
        if (id.isNotEmpty) _userNames[id] = v['name']?.toString() ?? '';
      }
    }

    // 고객 이름 매핑
    final customerResult = await _userService.getUsers(role: 'CUSTOMER');
    if (customerResult['success'] == true) {
      for (final c in (customerResult['users'] ?? [])) {
        final id = c['id']?.toString() ?? '';
        if (id.isNotEmpty) _userNames[id] = c['name']?.toString() ?? '';
      }
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

    // 최근 활동 로그 (E-5)
    final logResult = await _logService.getLogs(limit: 20);
    if (logResult['success'] == true) {
      _logs = logResult['logs'] ?? [];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ── 통계 헬퍼 ──

  String _eventStatus(Map<String, dynamic> e) {
    if (e['deletedAt'] != null) return '삭제됨';
    try {
      final now = DateTime.now();
      final s = DateTime.parse(e['startDate'].toString());
      final end = DateTime.parse(e['endDate'].toString());
      if (now.isBefore(s)) return '예정';
      if (now.isAfter(end)) return '종료';
      return '진행중';
    } catch (_) { return '미정'; }
  }

  List<Map<String, dynamic>> _eventsByStatus(String status) =>
      _events.where((e) => _eventStatus(e) == status).toList();

  int _eventContractCount(String eventId) =>
      _allContracts.where((c) => c['eventId'] == eventId && c['status'] == 'CONFIRMED').length;

  int _eventRevenue(String eventId) =>
      _allContracts.where((c) => c['eventId'] == eventId && c['status'] == 'CONFIRMED')
          .fold<int>(0, (s, c) => s + ((c['depositAmount'] ?? 0) as int));


  List<dynamic> get _unapprovedVendors => _vendors.where((v) => v['isApproved'] != true).toList();

  List<dynamic> get _cancelRequests => _allContracts.where((c) => c['status'] == 'CANCEL_REQUESTED').toList();

  // 오늘 시작 행사
  List<Map<String, dynamic>> get _todayEvents => _events.where((e) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final s = DateTime.parse(e['startDate'].toString());
      return DateTime(s.year, s.month, s.day) == today;
    } catch (_) { return false; }
  }).toList();

  // 슬라이드 패널 열기/닫기
  void _openPanel(Widget panel) => setState(() => _slidePanel = panel);
  void _closePanel() => setState(() => _slidePanel = null);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // 스켈레톤 로딩
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 160, height: 28, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 24),
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(height: 100, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12))),
            )),
          ],
        ),
      );
    }

    final isCompact = MediaQuery.of(context).size.width < 1024;
    final pad = isCompact ? 16.0 : 28.0;

    // E-6: 슬라이드 패널이 열려있으면 오버레이
    return Stack(
      children: [
        // 메인 콘텐츠
        SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 + 새로고침
              Row(
                children: [
                  const Text('대시보드', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadAllData,
                    icon: const Icon(Icons.refresh),
                    tooltip: '새로고침',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ═══ 메인 + 사이드 레이아웃 ═══
              if (isCompact)
                // 아이패드: 1컬럼 세로 배치
                Column(
                  children: [
                    _buildActionRequired(),
                    const SizedBox(height: 16),
                    _buildEventBoard(isCompact),
                    const SizedBox(height: 16),
                    _buildContractPipeline(),
                    const SizedBox(height: 16),
                    _buildRankingSection(),
                    const SizedBox(height: 16),
                    _buildActivityFeed(),
                  ],
                )
              else
                // PC: 2컬럼 (70% 메인 + 30% 사이드)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 메인 (70%)
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          _buildActionRequired(),
                          const SizedBox(height: 16),
                          _buildEventBoard(isCompact),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildContractPipeline()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildRankingSection()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 사이드 (30%) — 활동 피드
                    Expanded(
                      flex: 3,
                      child: _buildActivityFeed(),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // E-6: 슬라이드 패널 오버레이
        if (_slidePanel != null) ...[
          // 어두운 배경 (클릭 시 닫기)
          GestureDetector(
            onTap: _closePanel,
            child: Container(color: Colors.black26),
          ),
          // 패널 (오른쪽에서 슬라이드)
          Positioned(
            top: 0, bottom: 0, right: 0,
            width: isCompact ? MediaQuery.of(context).size.width * 0.85 : 420,
            child: Material(
              elevation: 16,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // 패널 닫기 헤더
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                      child: Row(
                        children: [
                          const Text('상세 보기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          IconButton(onPressed: _closePanel, icon: const Icon(Icons.close), iconSize: 20),
                        ],
                      ),
                    ),
                    // 패널 내용
                    Expanded(child: _slidePanel!),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // E-1: 처리 필요 — 인라인 액션 (바로 승인/거부)
  // ═══════════════════════════════════════════════════
  Widget _buildActionRequired() {
    final unapproved = _unapprovedVendors;
    final cancelReqs = _cancelRequests;
    final todayEvts = _todayEvents;

    if (unapproved.isEmpty && cancelReqs.isEmpty && todayEvts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 22),
            SizedBox(width: 10),
            Text('모든 항목이 처리되었습니다', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('처리 필요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.red)),
              const Spacer(),
              Text('${unapproved.length + cancelReqs.length + todayEvts.length}건', style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
            ],
          ),
          const SizedBox(height: 12),

          // 미승인 업체 (인라인 승인/거부)
          if (unapproved.isNotEmpty) ...[
            _sectionLabel('미승인 업체', Icons.person_add, Colors.red, unapproved.length),
            const SizedBox(height: 6),
            ...unapproved.take(5).map((v) => _vendorActionCard(v)),
            if (unapproved.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.organizerWebUsers),
                  child: Text('외 ${unapproved.length - 5}건 더 보기', style: const TextStyle(fontSize: 12)),
                ),
              ),
            const SizedBox(height: 12),
          ],

          // 취소 요청 (인라인 상세보기)
          if (cancelReqs.isNotEmpty) ...[
            _sectionLabel('취소 요청', Icons.warning_amber, Colors.orange, cancelReqs.length),
            const SizedBox(height: 6),
            ...cancelReqs.take(3).map((c) => _cancelRequestCard(c)),
            const SizedBox(height: 12),
          ],

          // 오늘 시작 행사
          if (todayEvts.isNotEmpty) ...[
            _sectionLabel('오늘 시작 행사', Icons.event_available, AppColors.primary, todayEvts.length),
            const SizedBox(height: 6),
            ...todayEvts.map((e) => InkWell(
              onTap: () => context.go('/admin/events/${e['id']}'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Expanded(child: Text(e['title'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  // 미승인 업체 카드 (바로 승인/거부)
  Widget _vendorActionCard(dynamic vendor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          // 업체명 + 연락처
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vendor['name'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(formatPhone(vendor['phone']?.toString()), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // 사업자등록증 여부
          if (vendor['businessLicenseImage'] != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.verified, size: 16, color: AppColors.success),
            ),
          // 승인 버튼
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () => _approveVendor(vendor),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('승인'),
            ),
          ),
          const SizedBox(width: 6),
          // 거부 버튼
          SizedBox(
            height: 32,
            child: OutlinedButton(
              onPressed: () => _rejectVendor(vendor),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('거부'),
            ),
          ),
        ],
      ),
    );
  }

  // 취소 요청 카드
  Widget _cancelRequestCard(dynamic contract) {
    final customer = contract['customer'] as Map<String, dynamic>?;
    final product = contract['product'] as Map<String, dynamic>?;
    return InkWell(
      onTap: () => context.go('/admin/events/${contract['eventId']}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${customer?['name'] ?? '-'} · ${product?['name'] ?? '-'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text('${contract['eventTitle']} · ${_fmt.format(contract['depositAmount'] ?? 0)}원', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
              child: const Text('취소요청', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  // 인라인 승인
  Future<void> _approveVendor(dynamic vendor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('업체 승인'),
        content: Text('${vendor['name']}을(를) 승인하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppColors.success), child: const Text('승인')),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await _userService.approveUser(vendor['id']);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${vendor['name']} 승인 완료')));
      _loadAllData(); // 데이터 갱신
    }
  }

  // 인라인 거부
  Future<void> _rejectVendor(dynamic vendor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('업체 거부'),
        content: Text('${vendor['name']}의 가입을 거부하시겠습니까?\n계정이 삭제됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('거부')),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await _userService.rejectUser(vendor['id']);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${vendor['name']} 거부 완료')));
      _loadAllData();
    }
  }

  // ═══════════════════════════════════════════════════
  // E-2: 행사 현황 보드 (칸반형 카드)
  // ═══════════════════════════════════════════════════
  Widget _buildEventBoard(bool isCompact) {
    final active = _eventsByStatus('진행중');
    final upcoming = _eventsByStatus('예정');
    final ended = _eventsByStatus('종료');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              const Text('행사 현황', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(AppRoutes.organizerWebEvents),
                child: const Text('전체보기 →', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 카테고리 헤더 (진행중/예정/종료)
          if (_events.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.event_note, size: 48, color: AppColors.textHint),
                  SizedBox(height: 8),
                  Text('등록된 행사가 없습니다', style: TextStyle(color: AppColors.textHint)),
                ],
              ),
            ))
          else ...[
            // 진행중 행사 (가장 중요 — 크게)
            if (active.isNotEmpty) ...[
              _statusHeader('진행중', AppColors.success, active.length),
              const SizedBox(height: 8),
              ...active.map((e) => _eventCard(e, isActive: true)),
              const SizedBox(height: 12),
            ],
            // 예정 행사
            if (upcoming.isNotEmpty) ...[
              _statusHeader('예정', AppColors.primary, upcoming.length),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: upcoming.map((e) => _eventCard(e, isActive: false)).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // 종료 행사 (축소)
            if (ended.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                title: _statusHeader('종료', AppColors.textSecondary, ended.length),
                children: ended.take(5).map((e) => _eventCard(e, isActive: false, compact: true)).toList(),
              ),
          ],
        ],
      ),
    );
  }

  // 상태 헤더
  Widget _statusHeader(String label, Color color, int count) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 4),
        Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  // 행사 카드 — 모든 숫자 클릭 가능
  Widget _eventCard(Map<String, dynamic> event, {bool isActive = false, bool compact = false}) {
    final eid = event['id']?.toString() ?? '';
    final contracts = _eventContractCount(eid);
    final revenue = _eventRevenue(eid);
    final status = _eventStatus(event);

    // D-day 계산
    String dayLabel = '';
    try {
      final now = DateTime.now();
      final start = DateTime.parse(event['startDate'].toString());
      if (status == '예정') {
        final diff = start.difference(DateTime(now.year, now.month, now.day)).inDays;
        dayLabel = 'D-$diff';
      } else if (status == '진행중') {
        final diff = DateTime(now.year, now.month, now.day).difference(DateTime(start.year, start.month, start.day)).inDays + 1;
        dayLabel = '진행 $diff일차';
      }
    } catch (_) {}

    if (compact) {
      // 종료 행사: 한 줄 간략 표시
      return InkWell(
        onTap: () => context.go('/admin/events/$eid'),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Expanded(child: Text(event['title'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Text('$contracts건', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Text('${_fmt.format(revenue)}원', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withValues(alpha: 0.03) : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: isActive ? Border.all(color: AppColors.primary.withValues(alpha: 0.15)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + D-day
          Row(
            children: [
              Expanded(child: Text(event['title'] ?? '-', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              if (dayLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(dayLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.success : AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // 핵심 숫자 (모두 클릭 가능!)
          Row(
            children: [
              _clickableStat('계약', '$contracts건', () => context.go('/admin/events/$eid')),
              const SizedBox(width: 20),
              _clickableStat('매출', '${_fmt.format(revenue)}원', () => context.go('/admin/events/$eid'), color: AppColors.priceRed),
              const Spacer(),
              // 상세보기 버튼
              TextButton.icon(
                onPressed: () => context.go('/admin/events/$eid'),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('상세', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 클릭 가능한 숫자
  Widget _clickableStat(String label, String value, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // E-3: 계약 파이프라인
  // ═══════════════════════════════════════════════════
  Widget _buildContractPipeline() {
    final total = _allContracts.length;
    final confirmed = _allContracts.where((c) => c['status'] == 'CONFIRMED').length;
    final pending = _allContracts.where((c) => c['status'] == 'PENDING').length;
    final cancelReq = _allContracts.where((c) => c['status'] == 'CANCEL_REQUESTED').length;
    final cancelled = _allContracts.where((c) => c['status'] == 'CANCELLED').length;
    final totalRevenue = _allContracts.where((c) => c['status'] == 'CONFIRMED')
        .fold<int>(0, (s, c) => s + ((c['depositAmount'] ?? 0) as int));
    final cancelRate = total > 0 ? (cancelled / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('계약 현황', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),

          if (total == 0)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('계약이 없습니다', style: TextStyle(color: AppColors.textHint)),
            ))
          else ...[
            // 파이프라인 막대들 (클릭 가능)
            _pipelineBar('확정', confirmed, total, AppColors.success, 'CONFIRMED'),
            const SizedBox(height: 8),
            _pipelineBar('대기', pending, total, AppColors.warning, 'PENDING'),
            const SizedBox(height: 8),
            _pipelineBar('취소요청', cancelReq, total, Colors.orange, 'CANCEL_REQUESTED'),
            const SizedBox(height: 8),
            _pipelineBar('취소', cancelled, total, AppColors.textSecondary, 'CANCELLED'),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            // 요약 숫자
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('총 매출', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                      Text('${_fmt.format(totalRevenue)}원', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.priceRed)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('취소율', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                      Text(
                        '${cancelRate.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: cancelRate > 10 ? Colors.red : cancelRate > 5 ? Colors.orange : AppColors.success),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 파이프라인 막대 (클릭 → 해당 상태 계약 패널)
  Widget _pipelineBar(String label, int count, int total, Color color, String status) {
    final ratio = total > 0 ? count / total : 0.0;
    final pct = (ratio * 100).toStringAsFixed(0);
    return InkWell(
      onTap: () {
        // E-6: 슬라이드 패널에 해당 상태 계약 표시
        final filtered = _allContracts.where((c) => c['status'] == status).toList();
        _openPanel(_buildContractListPanel(label, filtered));
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 56, child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500))),
            const SizedBox(width: 8),
            // 막대
            Expanded(
              child: Stack(
                children: [
                  Container(height: 22, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4))),
                  FractionallySizedBox(
                    widthFactor: ratio.clamp(0.02, 1.0),
                    child: Container(height: 22, decoration: BoxDecoration(color: color.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4))),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 60, child: Text('$count건 ($pct%)', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // E-4: 인기 품목 / 업체 성과 (탭 전환)
  // ═══════════════════════════════════════════════════
  Widget _buildRankingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 탭 헤더
          Row(
            children: [
              _tabChip('인기 품목', !_showVendorPerf, () => setState(() => _showVendorPerf = false)),
              const SizedBox(width: 8),
              _tabChip('업체 성과', _showVendorPerf, () => setState(() => _showVendorPerf = true)),
            ],
          ),
          const SizedBox(height: 12),
          _showVendorPerf ? _buildVendorRanking() : _buildProductRanking(),
        ],
      ),
    );
  }

  Widget _tabChip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  // 인기 품목 순위
  Widget _buildProductRanking() {
    // 품목별 계약수/매출 집계
    final Map<String, Map<String, dynamic>> productStats = {};
    for (final c in _allContracts.where((c) => c['status'] == 'CONFIRMED')) {
      final product = c['product'] as Map<String, dynamic>?;
      final pName = product?['name'] ?? '기타';
      final vendorName = product?['vendorName'] ?? '-';
      final deposit = (c['depositAmount'] ?? 0) as int;
      productStats.putIfAbsent(pName, () => {'vendor': vendorName, 'count': 0, 'revenue': 0});
      productStats[pName]!['count'] = (productStats[pName]!['count'] as int) + 1;
      productStats[pName]!['revenue'] = (productStats[pName]!['revenue'] as int) + deposit;
    }

    final sorted = productStats.entries.toList()
      ..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));

    if (sorted.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('데이터 없음', style: TextStyle(color: AppColors.textHint))));
    }

    return Column(
      children: sorted.take(5).toList().asMap().entries.map((entry) {
        final i = entry.key;
        final name = entry.value.key;
        final stats = entry.value.value;
        return InkWell(
          onTap: () {
            // 해당 품목 계약 목록 패널
            final filtered = _allContracts.where((c) =>
              c['status'] == 'CONFIRMED' && (c['product'] as Map?)?['name'] == name).toList();
            _openPanel(_buildContractListPanel('$name 계약', filtered));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 20, child: Text('${i + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: i < 3 ? AppColors.organizer : AppColors.textHint))),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      Text(stats['vendor'] ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                ),
                Text('${stats['count']}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Text('${_fmt.format(stats['revenue'])}원', style: const TextStyle(fontSize: 13, color: AppColors.priceRed, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 업체 성과 순위
  Widget _buildVendorRanking() {
    final Map<String, Map<String, dynamic>> vendorStats = {};
    for (final c in _allContracts.where((c) => c['status'] == 'CONFIRMED')) {
      final product = c['product'] as Map<String, dynamic>?;
      final vName = product?['vendorName'] ?? '미배정';
      final deposit = (c['depositAmount'] ?? 0) as int;
      vendorStats.putIfAbsent(vName, () => {'count': 0, 'revenue': 0});
      vendorStats[vName]!['count'] = (vendorStats[vName]!['count'] as int) + 1;
      vendorStats[vName]!['revenue'] = (vendorStats[vName]!['revenue'] as int) + deposit;
    }

    final sorted = vendorStats.entries.toList()
      ..sort((a, b) => (b.value['revenue'] as int).compareTo(a.value['revenue'] as int));

    if (sorted.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('데이터 없음', style: TextStyle(color: AppColors.textHint))));
    }

    return Column(
      children: sorted.take(5).toList().asMap().entries.map((entry) {
        final i = entry.key;
        final name = entry.value.key;
        final stats = entry.value.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(width: 20, child: Text('${i + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: i < 3 ? AppColors.organizer : AppColors.textHint))),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
              Text('${stats['count']}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Text('${_fmt.format(stats['revenue'])}원', style: const TextStyle(fontSize: 13, color: AppColors.priceRed, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════
  // E-5: 실시간 활동 피드 (타임라인)
  // ═══════════════════════════════════════════════════
  Widget _buildActivityFeed() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('실시간 활동', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(AppRoutes.organizerWebLogs),
                child: const Text('전체 →', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('활동 기록이 없습니다', style: TextStyle(color: AppColors.textHint, fontSize: 13))),
            )
          else
            ...(_logs.take(10).toList().asMap().entries.map((entry) {
              final log = entry.value;
              final action = log['action']?.toString() ?? '';
              final detail = log['detail']?.toString() ?? '';
              final userId = log['userId']?.toString() ?? '';
              final userName = _userNames[userId] ?? '알 수 없음';

              // 시간 표시
              String timeLabel = '';
              try {
                final date = DateTime.parse(log['createdAt'].toString());
                final diff = DateTime.now().difference(date);
                if (diff.inMinutes < 1) {
                  timeLabel = '방금';
                } else if (diff.inMinutes < 60) {
                  timeLabel = '${diff.inMinutes}분 전';
                } else if (diff.inHours < 24) {
                  timeLabel = '${diff.inHours}시간 전';
                } else {
                  timeLabel = '${diff.inDays}일 전';
                }
              } catch (_) {}

              // 액션별 아이콘/색상
              final style = _logStyle(action);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타임라인 아이콘
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: (style['color'] as Color).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(style['icon'] as IconData, size: 14, color: style['color'] as Color),
                    ),
                    const SizedBox(width: 10),
                    // 내용
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 사용자명 + 시간
                          Row(
                            children: [
                              Text(userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Text(timeLabel, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // 상세
                          Text(detail.isNotEmpty ? detail : (style['label'] as String? ?? action),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            })),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // E-6: 슬라이드 패널 — 계약 목록 표시
  // ═══════════════════════════════════════════════════
  Widget _buildContractListPanel(String title, List<dynamic> contracts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('$title (${contracts.length}건)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        const Divider(height: 1),
        Expanded(
          child: contracts.isEmpty
              ? const Center(child: Text('해당 계약이 없습니다', style: TextStyle(color: AppColors.textHint)))
              : ListView.separated(
                  itemCount: contracts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final c = contracts[index];
                    final customer = c['customer'] as Map<String, dynamic>?;
                    final product = c['product'] as Map<String, dynamic>?;
                    final deposit = c['depositAmount'] ?? 0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(customer?['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      subtitle: Text('${product?['name'] ?? '-'} · ${c['eventTitle'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: Text('${_fmt.format(deposit)}원', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.priceRed)),
                      onTap: () {
                        _closePanel();
                        final eventId = c['eventId']?.toString() ?? '';
                        if (eventId.isNotEmpty) context.go('/admin/events/$eventId');
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // 공통 헬퍼
  // ═══════════════════════════════════════════════════

  Widget _sectionLabel(String label, IconData icon, Color color, int count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text('$label ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    );
  }

  Map<String, dynamic> _logStyle(String action) {
    const map = {
      'LOGIN': {'icon': Icons.login, 'color': Colors.blue, 'label': '로그인'},
      'REGISTER': {'icon': Icons.person_add, 'color': Colors.green, 'label': '회원가입'},
      'EVENT_CREATE': {'icon': Icons.event, 'color': Colors.purple, 'label': '행사 생성'},
      'EVENT_ENTER': {'icon': Icons.door_front_door, 'color': Colors.teal, 'label': '행사 입장'},
      'PRODUCT_CREATE': {'icon': Icons.add_box, 'color': Colors.orange, 'label': '상품 등록'},
      'CONTRACT_CREATE': {'icon': Icons.description, 'color': Colors.blue, 'label': '계약 생성'},
      'CONTRACT_CANCEL_REQUEST': {'icon': Icons.warning, 'color': Colors.orange, 'label': '취소 요청'},
      'PAYMENT_CREATE': {'icon': Icons.payment, 'color': Colors.green, 'label': '결제'},
      'PAYMENT_REFUND': {'icon': Icons.money_off, 'color': Colors.red, 'label': '환불'},
    };
    return map[action] ?? {'icon': Icons.circle, 'color': Colors.grey, 'label': action};
  }
}
