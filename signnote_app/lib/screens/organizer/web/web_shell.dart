import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';

// ============================================
// PC용 전체 레이아웃 셸 (WebShell)
//
// 구조:
// +------------------+---------------------------+
// |  Signnote 로고    |                           |
// |  [주관사] 뱃지    |   오른쪽에 각 페이지 내용   |
// |                  |                           |
// |  대시보드         |                           |
// |  행사 관리        |                           |
// |  계약 현황        |                           |
// |  품목 관리        |                           |
// |  사용자 관리      |                           |
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

/// 사이드바 위젯 — 역할에 따라 뱃지/메뉴 동적 표시
class _Sidebar extends StatefulWidget {
  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  String _currentRole = '';  // 현재 로그인한 사용자 역할

  // 전체 메뉴 항목 (어드민은 전부 표시, 주관사는 일부 제한)
  static const _allMenuItems = [
    _MenuItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: '대시보드', path: AppRoutes.organizerDashboard, adminOnly: false),
    _MenuItem(icon: Icons.event_outlined, activeIcon: Icons.event, label: '행사 관리', path: AppRoutes.organizerWebEvents, adminOnly: false),
    _MenuItem(icon: Icons.description_outlined, activeIcon: Icons.description, label: '계약 현황', path: AppRoutes.organizerWebContracts, adminOnly: false),
    _MenuItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: '품목 관리', path: AppRoutes.organizerWebProducts, adminOnly: false),
    _MenuItem(icon: Icons.people_outline, activeIcon: Icons.people, label: '사용자 관리', path: AppRoutes.organizerWebUsers, adminOnly: false),
    _MenuItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: '정산 관리', path: AppRoutes.organizerWebSettlements, adminOnly: false),
    _MenuItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: '활동 로그', path: AppRoutes.organizerWebLogs, adminOnly: true),
    _MenuItem(icon: Icons.person_outline, activeIcon: Icons.person, label: '마이페이지', path: AppRoutes.organizerWebMypage, adminOnly: false),
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  // 현재 로그인한 사용자의 역할 불러오기
  Future<void> _loadRole() async {
    final userInfo = await ApiService().getUserInfo();
    if (userInfo != null && mounted) {
      setState(() => _currentRole = userInfo['role'] ?? '');
    }
  }

  bool get _isAdmin => _currentRole == 'ADMIN';

  // 역할에 따른 뱃지 정보
  String get _badgeText => _isAdmin ? '관리자' : '주관사';
  Color get _badgeColor => _isAdmin ? Colors.red : AppColors.primary;

  // 역할에 따라 표시할 메뉴 필터링
  List<_MenuItem> get _menuItems {
    if (_isAdmin) return _allMenuItems;
    // 주관사는 adminOnly가 아닌 메뉴만 표시
    return _allMenuItems.where((m) => !m.adminOnly).toList();
  }

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

          const SizedBox(height: 32),

          // ── 메뉴 항목들 ──
          ...List.generate(_menuItems.length, (index) {
            final item = _menuItems[index];
            final isActive = currentPath.startsWith(item.path);
            return _buildMenuItem(
              context: context,
              icon: isActive ? item.activeIcon : item.icon,
              label: item.label,
              isActive: isActive,
              onTap: () => context.go(item.path),
            );
          }),

          const Spacer(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: AppColors.border),
          ),

          // ── 로그아웃 ──
          _buildMenuItem(
            context: context,
            icon: Icons.logout,
            label: '로그아웃',
            isActive: false,
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

  /// 사이드바 메뉴 항목 위젯
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
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
            decoration: BoxDecoration(
              // 선택된 메뉴: primary 배경색
              color: isActive
                  ? AppColors.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  // 선택된 메뉴: 흰 아이콘, 미선택: 회색 아이콘
                  color: isActive
                      ? AppColors.white
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    // 선택된 메뉴: 흰 글씨, 미선택: 검정 글씨
                    color: isActive
                        ? AppColors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 메뉴 항목 데이터 클래스
class _MenuItem {
  final IconData icon;        // 기본 아이콘
  final IconData activeIcon;  // 선택된 상태 아이콘
  final String label;         // 메뉴 이름
  final String path;          // URL 경로
  final bool adminOnly;       // 관리자 전용 메뉴 여부

  const _MenuItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    this.adminOnly = false,
  });
}
