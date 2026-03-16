import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import '../../services/event_service.dart';
import '../../services/notification_service.dart';

// ============================================
// PC용 전체 레이아웃 셸 (WebShell) — 고도화
//
// S-1: 글로벌 검색 (Ctrl+K)
// S-2: 알림 벨 + 카운트
// S-3: 관리자 프로필 영역 (아바타+이름+역할)
// S-4: 최근 방문 행사 바로가기
// S-5: 메뉴 항목별 실시간 카운트
// S-6: 행사 컨텍스트 표시 (현재 행사 하이라이트)
// S-7: 접힌 상태 툴팁
// ============================================

class WebShell extends StatefulWidget {
  final Widget child;

  const WebShell({super.key, required this.child});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  bool _sidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final autoCollapse = screenWidth < 1024;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            expanded: autoCollapse ? false : _sidebarExpanded,
            onToggle: autoCollapse ? null : () => setState(() => _sidebarExpanded = !_sidebarExpanded),
          ),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

/// 고도화된 사이드바
class _Sidebar extends StatefulWidget {
  final bool expanded;
  final VoidCallback? onToggle;

  const _Sidebar({required this.expanded, this.onToggle});

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  // 사용자 정보
  String _currentRole = '';
  String _userName = '';
  String _userEmail = '';

  // 폴더 상태
  bool _managementExpanded = true;
  bool _systemExpanded = true;

  // S-5: 카운트들
  int _unapprovedVendorCount = 0;
  int _activeEventCount = 0;
  int _totalCustomerCount = 0;
  int _unreadNotiCount = 0;

  // S-4: 최근 방문 행사
  List<Map<String, dynamic>> _recentEvents = [];

  // S-1: 검색 데이터
  List<Map<String, dynamic>> _allEvents = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadCounts();
    _loadEvents();
  }

  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    final userInfo = await ApiService().getUserInfo();
    if (userInfo != null && mounted) {
      setState(() {
        _currentRole = userInfo['role'] ?? '';
        _userName = userInfo['name'] ?? '사용자';
        _userEmail = userInfo['email'] ?? '';
      });
    }
  }

  // S-5: 카운트 로드
  Future<void> _loadCounts() async {
    // 미승인 업체
    final vendorResult = await UserService().getUsers(role: 'VENDOR');
    if (vendorResult['success'] == true && mounted) {
      final users = List<Map<String, dynamic>>.from(vendorResult['users'] ?? []);
      _unapprovedVendorCount = users.where((u) => u['isApproved'] != true).length;
    }

    // 고객 수
    final customerResult = await UserService().getUsers(role: 'CUSTOMER');
    if (customerResult['success'] == true && mounted) {
      _totalCustomerCount = (customerResult['users'] as List?)?.length ?? 0;
    }

    // 안 읽은 알림
    final notiResult = await NotificationService().getUnreadCount();
    if (notiResult['success'] == true && mounted) {
      _unreadNotiCount = (notiResult['count'] as num?)?.toInt() ?? 0;
    }

    if (mounted) setState(() {});
  }

  // S-4 + S-5: 행사 로드
  Future<void> _loadEvents() async {
    final result = await EventService().getEvents();
    if (result['success'] == true && mounted) {
      final events = (result['events'] as List? ?? [])
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      _allEvents = events;

      // S-5: 진행중 행사 수
      final now = DateTime.now();
      _activeEventCount = events.where((e) {
        try {
          final s = DateTime.parse(e['startDate'].toString());
          final end = DateTime.parse(e['endDate'].toString());
          return now.isAfter(s) && now.isBefore(end);
        } catch (_) { return false; }
      }).length;

      // S-4: 최근 3개 행사 (최신순)
      final sorted = List<Map<String, dynamic>>.from(events);
      sorted.sort((a, b) => (b['startDate']?.toString() ?? '').compareTo(a['startDate']?.toString() ?? ''));
      _recentEvents = sorted.take(3).toList();

      if (mounted) setState(() {});
    }
  }

  bool get _isAdmin => _currentRole == 'ADMIN';
  bool get _isExpanded => widget.expanded;

  String get _badgeText => _isAdmin ? '관리자' : '주관사';
  Color get _badgeColor => _isAdmin ? Colors.red : AppColors.organizer;

  // S-1: 검색 다이얼로그
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _SearchDialog(events: _allEvents),
    );
  }

  // S-2: 알림 팝업
  void _showNotificationPopup() {
    // 알림 페이지가 별도로 없으므로 대시보드로 이동
    context.go(AppRoutes.organizerDashboard);
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final sidebarWidth = _isExpanded ? 252.0 : 68.0;

    // S-6: 현재 보고 있는 행사 ID 추출
    String? currentEventId;
    final eventMatch = RegExp(r'/admin/events/([^/]+)').firstMatch(currentPath);
    if (eventMatch != null) currentEventId = eventMatch.group(1);
    // 현재 행사 이름
    String? currentEventName;
    if (currentEventId != null) {
      final event = _allEvents.where((e) => e['id']?.toString() == currentEventId).firstOrNull;
      currentEventName = event?['title']?.toString();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      // S-1: Ctrl+K 키보드 단축키
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.keyK &&
              HardwareKeyboard.instance.isControlPressed) {
            _showSearchDialog();
          }
        },
        child: Column(
          children: [
            const SizedBox(height: 14),

            // ══════ 로고 + 알림 벨 + 접기 버튼 ══════
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 10),
              child: _isExpanded
                  ? Row(
                      children: [
                        // 로고
                        InkWell(
                          onTap: () => context.go(AppRoutes.organizerDashboard),
                          child: Image.asset('assets/images/logo.png', height: 24, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 6),
                        // 역할 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(_badgeText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _badgeColor)),
                        ),
                        const Spacer(),
                        // S-2: 알림 벨
                        Stack(
                          children: [
                            IconButton(
                              onPressed: _showNotificationPopup,
                              icon: Icon(
                                _unreadNotiCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                                size: 20,
                                color: _unreadNotiCount > 0 ? AppColors.organizer : AppColors.textSecondary,
                              ),
                              tooltip: '알림',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                            if (_unreadNotiCount > 0)
                              Positioned(
                                right: 0, top: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    _unreadNotiCount > 99 ? '99+' : '$_unreadNotiCount',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // 접기 버튼
                        if (widget.onToggle != null)
                          IconButton(
                            onPressed: widget.onToggle,
                            icon: const Icon(Icons.menu_open, size: 18),
                            tooltip: '사이드바 접기',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            color: AppColors.textHint,
                          ),
                      ],
                    )
                  : Column(
                      children: [
                        if (widget.onToggle != null)
                          IconButton(
                            onPressed: widget.onToggle,
                            icon: const Icon(Icons.menu, size: 22),
                            tooltip: '사이드바 펼치기',
                            color: AppColors.textSecondary,
                          )
                        else
                          InkWell(
                            onTap: () => context.go(AppRoutes.organizerDashboard),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset('assets/images/logo.png', height: 22, fit: BoxFit.contain),
                            ),
                          ),
                        // 접힌 상태에서도 알림 벨
                        if (_unreadNotiCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Stack(
                              children: [
                                Icon(Icons.notifications_active, size: 20, color: AppColors.organizer),
                                Positioned(
                                  right: 0, top: 0,
                                  child: Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),

            const SizedBox(height: 12),

            // ══════ S-1: 검색 바 ══════
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: InkWell(
                  onTap: _showSearchDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 16, color: AppColors.textHint),
                        const SizedBox(width: 8),
                        const Text('검색', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Ctrl+K', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // ══════ 메뉴 항목들 ══════

            // 대시보드
            _buildMenuItem(
              context: context,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: '대시보드',
              path: AppRoutes.organizerDashboard,
              currentPath: currentPath,
            ),

            const SizedBox(height: 4),

            // 관리 폴더
            if (_isExpanded)
              _buildFolder(
                context: context,
                label: '관리',
                expanded: _managementExpanded,
                onToggle: () => setState(() => _managementExpanded = !_managementExpanded),
                currentPath: currentPath,
                children: [
                  // S-5: 행사 관리 + 진행중 수
                  _FolderChild(icon: Icons.event_outlined, label: '행사 관리', path: AppRoutes.organizerWebEvents,
                    countText: _activeEventCount > 0 ? '$_activeEventCount' : null),
                  // 업체 관리 + 미승인 수
                  _FolderChild(icon: Icons.business_outlined, label: '업체 관리', path: AppRoutes.organizerWebUsers,
                    badgeCount: _unapprovedVendorCount),
                  // S-5: 고객 관리 + 전체 수
                  _FolderChild(icon: Icons.people_outline, label: '고객 관리', path: AppRoutes.organizerWebCustomers,
                    countText: _totalCustomerCount > 0 ? '$_totalCustomerCount' : null),
                ],
              )
            else ...[
              _buildIconOnlyItem(context, Icons.event_outlined, '행사 관리', AppRoutes.organizerWebEvents, currentPath),
              _buildIconOnlyItem(context, Icons.business_outlined, '업체 관리', AppRoutes.organizerWebUsers, currentPath, badgeCount: _unapprovedVendorCount),
              _buildIconOnlyItem(context, Icons.people_outline, '고객 관리', AppRoutes.organizerWebCustomers, currentPath),
            ],

            // S-6: 현재 보고 있는 행사 표시
            if (_isExpanded && currentEventName != null)
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 12, top: 2, bottom: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.subdirectory_arrow_right, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(currentEventName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),

            // 시스템 폴더 (관리자 전용)
            if (_isAdmin) ...[
              const SizedBox(height: 4),
              if (_isExpanded)
                _buildFolder(
                  context: context,
                  label: '시스템',
                  expanded: _systemExpanded,
                  onToggle: () => setState(() => _systemExpanded = !_systemExpanded),
                  currentPath: currentPath,
                  children: [
                    _FolderChild(icon: Icons.history_outlined, label: '활동 로그', path: AppRoutes.organizerWebLogs),
                  ],
                )
              else
                _buildIconOnlyItem(context, Icons.history_outlined, '활동 로그', AppRoutes.organizerWebLogs, currentPath),
            ],

            // ══════ S-4: 최근 방문 행사 ══════
            if (_isExpanded && _recentEvents.isNotEmpty) ...[
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('최근 행사', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint, letterSpacing: 0.5)),
                    const Spacer(),
                    InkWell(
                      onTap: () => context.go(AppRoutes.organizerWebEvents),
                      child: const Text('전체', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              ..._recentEvents.map((event) {
                final eid = event['id']?.toString() ?? '';
                final isViewing = currentEventId == eid;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                  child: InkWell(
                    onTap: () => context.go('/admin/events/$eid'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isViewing ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_note, size: 14, color: isViewing ? AppColors.primary : AppColors.textHint),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event['title'] ?? '-',
                              style: TextStyle(fontSize: 12, fontWeight: isViewing ? FontWeight.w600 : FontWeight.w400,
                                color: isViewing ? AppColors.primary : AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 14, color: AppColors.textHint),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ] else
              const Spacer(),

            // ══════ S-3: 프로필 영역 ══════
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: InkWell(
                  onTap: () => context.go(AppRoutes.organizerWebMypage),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        // 아바타
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _badgeColor,
                          child: Text(
                            _userName.isNotEmpty ? _userName[0] : '?',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 이름 + 이메일
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                              Text(_userEmail, style: const TextStyle(fontSize: 10, color: AppColors.textHint), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              // 접힌 상태: 아바타만
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Tooltip(
                  message: _userName,
                  child: InkWell(
                    onTap: () => context.go(AppRoutes.organizerWebMypage),
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: _badgeColor,
                      child: Text(
                        _userName.isNotEmpty ? _userName[0] : '?',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // 로그아웃
            _buildActionItem(
              context: context, icon: Icons.logout, label: '로그아웃',
              onTap: () async {
                await AuthService().logout();
                if (context.mounted) context.go(AppRoutes.login);
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ══════ 위젯 빌더들 ══════

  Widget _buildMenuItem({
    required BuildContext context, required IconData icon, required IconData activeIcon,
    required String label, required String path, required String currentPath,
  }) {
    final isActive = currentPath.startsWith(path);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 12 : 8, vertical: 2),
      child: _isExpanded
          ? Material(
              color: Colors.transparent, borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => context.go(path), borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(isActive ? activeIcon : icon, size: 20, color: isActive ? AppColors.white : AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text(label, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? AppColors.white : AppColors.textPrimary)),
                  ]),
                ),
              ),
            )
          // S-7: 접힌 상태 + 툴팁
          : Tooltip(
              message: label,
              child: Material(
                color: Colors.transparent, borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => context.go(path), borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Icon(isActive ? activeIcon : icon, size: 22,
                      color: isActive ? AppColors.white : AppColors.textSecondary)),
                  ),
                ),
              ),
            ),
    );
  }

  // S-7: 접힌 상태 아이콘 + 툴팁
  Widget _buildIconOnlyItem(BuildContext context, IconData icon, String tooltip, String path, String currentPath, {int badgeCount = 0}) {
    final isActive = currentPath.startsWith(path) ||
        (path == AppRoutes.organizerWebEvents && currentPath.startsWith('/admin/events'));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Tooltip(
        message: badgeCount > 0 ? '$tooltip ($badgeCount)' : tooltip,
        child: Material(
          color: Colors.transparent, borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => context.go(path), borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(alignment: Alignment.center, children: [
                Icon(icon, size: 22, color: isActive ? AppColors.primary : AppColors.textSecondary),
                if (badgeCount > 0)
                  Positioned(top: 0, right: 8, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: Text('$badgeCount', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                  )),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolder({
    required BuildContext context, required String label, required bool expanded,
    required VoidCallback onToggle, required String currentPath, required List<_FolderChild> children,
  }) {
    final hasActiveChild = children.any((c) =>
      currentPath.startsWith(c.path) ||
      (c.path == AppRoutes.organizerWebEvents && currentPath.startsWith('/admin/events')));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: InkWell(
          onTap: onToggle, borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16,
                color: hasActiveChild ? AppColors.primary : AppColors.textHint),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: hasActiveChild ? AppColors.primary : AppColors.textHint, letterSpacing: 0.5)),
            ]),
          ),
        ),
      ),
      if (expanded) ...children.map((child) {
        final isActive = currentPath.startsWith(child.path) ||
            (child.path == AppRoutes.organizerWebEvents && currentPath.startsWith('/admin/events'));
        return Padding(
          padding: const EdgeInsets.only(left: 24, right: 12, top: 1, bottom: 1),
          child: InkWell(
            onTap: () => context.go(child.path), borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Container(width: 2, height: 14, margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: isActive ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(1))),
                Icon(child.icon, size: 16, color: isActive ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(child: Text(child.label, style: TextStyle(fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppColors.primary : AppColors.textPrimary))),
                // S-5: 카운트 텍스트 (연한 회색)
                if (child.countText != null)
                  Text(child.countText!, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                // 빨간 뱃지
                if (child.badgeCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: Text('${child.badgeCount}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ]),
            ),
          ),
        );
      }),
    ]);
  }

  Widget _buildActionItem({required BuildContext context, required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 12 : 8, vertical: 2),
      child: _isExpanded
          ? InkWell(
              onTap: onTap, borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  Icon(icon, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ]),
              ),
            )
          : Tooltip(
              message: label,
              child: InkWell(
                onTap: onTap, borderRadius: BorderRadius.circular(8),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(child: Icon(icon, size: 20, color: AppColors.textSecondary))),
              ),
            ),
    );
  }
}

// ══════ S-1: 글로벌 검색 다이얼로그 ══════
class _SearchDialog extends StatefulWidget {
  final List<Map<String, dynamic>> events;
  const _SearchDialog({required this.events});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  void _search(String query) {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _results = widget.events.where((e) {
        final title = (e['title'] ?? '').toString().toLowerCase();
        final site = (e['siteName'] ?? '').toString().toLowerCase();
        final org = (e['organizer']?['name'] ?? '').toString().toLowerCase();
        return title.contains(q) || site.contains(q) || org.contains(q);
      }).toList();
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 420),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 검색 입력
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: '행사명, 현장명, 주관사명 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            // 결과
            if (_results.isEmpty && _controller.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('검색 결과가 없습니다', style: TextStyle(color: AppColors.textHint)),
              )
            else if (_results.isNotEmpty)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = _results[index];
                    return ListTile(
                      leading: const Icon(Icons.event, color: AppColors.primary, size: 20),
                      title: Text(e['title'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text('${e['organizer']?['name'] ?? '-'} · ${e['siteName'] ?? '-'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/admin/events/${e['id']}');
                      },
                    );
                  },
                ),
              )
            else
              // 빈 상태 — 최근 행사 추천
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.search, size: 32, color: AppColors.textHint),
                    const SizedBox(height: 8),
                    const Text('행사명, 현장명, 주관사명으로\n검색할 수 있습니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════ 데이터 ══════
class _FolderChild {
  final IconData icon;
  final String label;
  final String path;
  final int badgeCount;
  final String? countText; // S-5: 연한 회색 숫자

  const _FolderChild({required this.icon, required this.label, required this.path, this.badgeCount = 0, this.countText});
}
