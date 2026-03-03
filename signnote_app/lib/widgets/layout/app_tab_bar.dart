import 'package:flutter/material.dart';
import '../../config/theme.dart';

// ============================================
// AppTabBar - 하단 탭 메뉴
//
// 디자인 기준:
//   고객용 (4탭): 홈 / 장바구니 / 계약함 / 마이페이지
//   업체용 (3탭): 홈 / 계약함 / 마이페이지
//   주관사용 (3탭): 홈 / 계약함 / 마이페이지
//
// 사용 예시:
//   AppTabBar.customer(currentIndex: 0, onTap: (index) {})
//   AppTabBar.vendor(currentIndex: 0, onTap: (index) {})
// ============================================

class AppTabBar extends StatelessWidget {
  final int currentIndex;                    // 현재 선택된 탭 번호 (0부터)
  final ValueChanged<int> onTap;             // 탭 눌렀을 때 실행할 동작
  final List<BottomNavigationBarItem> items; // 탭 아이템 목록

  const AppTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  // 고객용 탭바 (4탭: 홈, 장바구니, 계약함, 마이페이지)
  factory AppTabBar.customer({
    required int currentIndex,
    required ValueChanged<int> onTap,
    int cartBadgeCount = 0,   // 장바구니에 담긴 개수
  }) {
    return AppTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: cartBadgeCount > 0
              ? Badge(
                  label: Text('$cartBadgeCount'),
                  child: const Icon(Icons.shopping_cart_outlined),
                )
              : const Icon(Icons.shopping_cart_outlined),
          activeIcon: cartBadgeCount > 0
              ? Badge(
                  label: Text('$cartBadgeCount'),
                  child: const Icon(Icons.shopping_cart),
                )
              : const Icon(Icons.shopping_cart),
          label: '장바구니',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: '계약함',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: '마이페이지',
        ),
      ],
    );
  }

  // 업체용 탭바 (3탭: 홈, 계약함, 마이페이지)
  factory AppTabBar.vendor({
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return AppTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: '계약함',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: '마이페이지',
        ),
      ],
    );
  }

  // 주관사용 탭바 (3탭: 홈, 계약함, 마이페이지) — 업체와 동일
  factory AppTabBar.organizer({
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return AppTabBar.vendor(
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary,           // 선택: 파란색
      unselectedItemColor: AppColors.textSecondary,   // 미선택: 회색
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: items,
    );
  }
}
