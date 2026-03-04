import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../services/auth_service.dart';

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

/// 사이드바 위젯
class _Sidebar extends StatelessWidget {
  // 메뉴 항목 정의
  static const _menuItems = [
    _MenuItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: '대시보드',
      path: AppRoutes.organizerDashboard,
    ),
    _MenuItem(
      icon: Icons.event_outlined,
      activeIcon: Icons.event,
      label: '행사 관리',
      path: AppRoutes.organizerWebEvents,
    ),
    _MenuItem(
      icon: Icons.description_outlined,
      activeIcon: Icons.description,
      label: '계약 현황',
      path: AppRoutes.organizerWebContracts,
    ),
    _MenuItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: '품목 관리',
      path: AppRoutes.organizerWebProducts,
    ),
    _MenuItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: '사용자 관리',
      path: AppRoutes.organizerWebUsers,
    ),
    _MenuItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: '정산 관리',
      path: AppRoutes.organizerWebSettlements,
    ),
    _MenuItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: '활동 로그',
      path: AppRoutes.organizerWebLogs,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // 현재 URL 경로 가져오기
    final currentPath = GoRouterState.of(context).uri.toString();

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),  // 오른쪽 테두리선
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // ── 로고 + 뱃지 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Signnote 로고 이미지
                Image.asset(
                  'assets/images/logo.png',
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                // [주관사] 역할 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '주관사',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── 메뉴 항목들 ──
          ...List.generate(_menuItems.length, (index) {
            final item = _menuItems[index];
            // 현재 페이지인지 확인 (URL 경로 비교)
            final isActive = currentPath.startsWith(item.path);

            return _buildMenuItem(
              context: context,
              icon: isActive ? item.activeIcon : item.icon,
              label: item.label,
              isActive: isActive,
              onTap: () => context.go(item.path),
            );
          }),

          const Spacer(),  // 아래쪽으로 밀기

          // ── 구분선 ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: AppColors.border),
          ),

          // ── 로그아웃 버튼 ──
          _buildMenuItem(
            context: context,
            icon: Icons.logout,
            label: '로그아웃',
            isActive: false,
            onTap: () async {
              await AuthService().logout();
              if (context.mounted) {
                context.go(AppRoutes.login);  // 로그인 화면으로 이동
              }
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

  const _MenuItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
