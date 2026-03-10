import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/user_service.dart';

// ============================================
// PC용 전체 레이아웃 셸 (WebShell)
//
// 구조:
// +------------------+---------------------------+
// |  Signnote 로고    |                           |
// |  [관리자] 뱃지    |   오른쪽에 각 페이지 내용   |
// |                  |                           |
// |  대시보드         |                           |
// |  ▸ 관리          |                           |
// |    행사 관리      |                           |
// |    업체 관리      |                           |
// |    고객 관리      |                           |
// |  ▸ 시스템 (어드민)|                           |
// |    활동 로그      |                           |
// |  ─────────      |                           |
// |  로그아웃         |                           |
// +------------------+---------------------------+
//     240px 고정              나머지 영역
// ============================================

class WebShell extends StatelessWidget {
  final Widget child;  // GoRouter가 전달하는 현재 페이지 내용

  const WebShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── 왼쪽 사이드바 (240px 고정) ──
          _Sidebar(),

          // ── 오른쪽 콘텐츠 영역 ──
          Expanded(
            child: Container(
              color: AppColors.background,  // 연한 회색 배경 (#F5F5F5)
              child: child,                 // 현재 선택된 페이지
            ),
          ),
        ],
      ),
    );
  }
}

/// 사이드바 위젯 — 폴더형 트리 구조
class _Sidebar extends StatefulWidget {
  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  String _currentRole = '';  // 현재 로그인한 사용자 역할

  // 폴더 펼침 상태 (기본: 펼침)
  bool _managementExpanded = true;
  bool _systemExpanded = true;

  // 미승인 업체 수 (빨간 뱃지용)
  int _unapprovedVendorCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadUnapprovedVendorCount(); // 미승인 업체 수 로드
  }

  // 현재 로그인한 사용자의 역할 불러오기
  Future<void> _loadRole() async {
    final userInfo = await ApiService().getUserInfo();
    if (userInfo != null && mounted) {
      setState(() => _currentRole = userInfo['role'] ?? '');
    }
  }

  // 미승인 업체 수 가져오기 (사이드바 뱃지 표시용)
  Future<void> _loadUnapprovedVendorCount() async {
    final result = await UserService().getUsers(role: 'VENDOR');
    if (result['success'] == true && mounted) {
      final users = List<Map<String, dynamic>>.from(result['users'] ?? []);
      final unapproved = users.where((u) => u['isApproved'] != true).length;
      setState(() => _unapprovedVendorCount = unapproved);
    }
  }

  bool get _isAdmin => _currentRole == 'ADMIN';

  // 역할에 따른 뱃지 정보
  String get _badgeText => _isAdmin ? '관리자' : '주관사';
  Color get _badgeColor => _isAdmin ? Colors.red : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // ── 로고 + 역할 뱃지 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 로고 (클릭 시 대시보드 이동)
                InkWell(
                  onTap: () => context.go(AppRoutes.organizerDashboard),
                  child: Image.asset('assets/images/logo.png', height: 28, fit: BoxFit.contain),
                ),
                const SizedBox(height: 8),
                // 역할 뱃지 (어드민=빨간색, 주관사=파란색)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _badgeText,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _badgeColor),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 대시보드 (단독 메뉴) ──
          _buildMenuItem(
            context: context,
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: '대시보드',
            path: AppRoutes.organizerDashboard,
            currentPath: currentPath,
          ),

          const SizedBox(height: 4),

          // ── 관리 폴더 (행사/업체/고객) ──
          _buildFolder(
            context: context,
            icon: Icons.folder_outlined,
            activeIcon: Icons.folder,
            label: '관리',
            expanded: _managementExpanded,
            onToggle: () => setState(() => _managementExpanded = !_managementExpanded),
            currentPath: currentPath,
            children: [
              _FolderChild(icon: Icons.event_outlined, label: '행사 관리', path: AppRoutes.organizerWebEvents),
              _FolderChild(icon: Icons.business_outlined, label: '업체 관리', path: AppRoutes.organizerWebUsers, badgeCount: _unapprovedVendorCount),
              _FolderChild(icon: Icons.people_outline, label: '고객 관리', path: AppRoutes.organizerWebCustomers),
            ],
          ),

          // ── 시스템 폴더 (활동 로그 — 관리자 전용) ──
          if (_isAdmin) ...[
            const SizedBox(height: 4),
            _buildFolder(
              context: context,
              icon: Icons.folder_outlined,
              activeIcon: Icons.folder,
              label: '시스템',
              expanded: _systemExpanded,
              onToggle: () => setState(() => _systemExpanded = !_systemExpanded),
              currentPath: currentPath,
              children: [
                _FolderChild(icon: Icons.history_outlined, label: '활동 로그', path: AppRoutes.organizerWebLogs),
              ],
            ),
          ],

          const Spacer(),

          // ── 마이페이지 ──
          _buildMenuItem(
            context: context,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: '마이페이지',
            path: AppRoutes.organizerWebMypage,
            currentPath: currentPath,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: AppColors.border),
          ),

          // ── 로그아웃 ──
          _buildActionItem(
            context: context,
            icon: Icons.logout,
            label: '로그아웃',
            onTap: () async {
              await AuthService().logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 단독 메뉴 항목 (대시보드, 마이페이지)
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String path,
    required String currentPath,
  }) {
    final isActive = currentPath.startsWith(path);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => context.go(path),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(isActive ? activeIcon : icon, size: 20,
                  color: isActive ? AppColors.white : AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppColors.white : AppColors.textPrimary,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 폴더 (접기/펼치기 가능한 그룹)
  Widget _buildFolder({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool expanded,
    required VoidCallback onToggle,
    required String currentPath,
    required List<_FolderChild> children,
  }) {
    // 자식 중 하나라도 활성화면 폴더 강조
    final hasActiveChild = children.any((c) =>
      currentPath.startsWith(c.path) ||
      (c.path == AppRoutes.organizerWebEvents && currentPath.startsWith('/admin/events')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 폴더 헤더 (클릭하면 펼치기/접기)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    // 펼침/접힘 화살표
                    Icon(
                      expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                      size: 18,
                      color: hasActiveChild ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    // 폴더 아이콘
                    Icon(
                      expanded ? activeIcon : icon,
                      size: 18,
                      color: hasActiveChild ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(label, style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasActiveChild ? AppColors.primary : AppColors.textSecondary,
                      letterSpacing: 0.5,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 자식 메뉴들 (펼쳐진 상태에서만 표시)
        if (expanded) ...children.map((child) {
          final isActive = currentPath.startsWith(child.path) ||
              (child.path == AppRoutes.organizerWebEvents && currentPath.startsWith('/admin/events'));
          return Padding(
            padding: const EdgeInsets.only(left: 24, right: 12, top: 1, bottom: 1),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => context.go(child.path),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // 트리 연결선 느낌의 세로선
                      Container(
                        width: 2,
                        height: 16,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      Icon(child.icon, size: 18,
                        color: isActive ? AppColors.primary : AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(child.label, style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? AppColors.primary : AppColors.textPrimary,
                      )),
                      // 미승인 업체 수 빨간 뱃지 (0보다 클 때만 표시)
                      if (child.badgeCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${child.badgeCount}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 액션 항목 (로그아웃 등 — 경로 없이 콜백만)
  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 폴더 자식 항목 데이터 클래스
class _FolderChild {
  final IconData icon;
  final String label;
  final String path;
  final int badgeCount; // 빨간 뱃지 숫자 (0이면 표시 안 함)

  const _FolderChild({required this.icon, required this.label, required this.path, this.badgeCount = 0});
}
