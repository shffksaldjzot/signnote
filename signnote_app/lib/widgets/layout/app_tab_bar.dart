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

  // 고객용 탭바 (4탭: 홈, 장바구니, 계약함, 마이페이지) — 2차 디자인 아이콘 적용
  factory AppTabBar.customer({
    required int currentIndex,
    required ValueChanged<int> onTap,
    int cartBadgeCount = 0,   // 장바구니에 담긴 개수
  }) {
    return AppTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/customer/home_inactive.png', width: 24, height: 24),
          activeIcon: Image.asset('assets/icons/customer/home_active.png', width: 24, height: 24),
          label: '홈',
        ),
        // 장바구니 아이콘 (파일명이 뒤바뀌어있어서 active↔inactive 교차 사용)
        BottomNavigationBarItem(
          icon: cartBadgeCount > 0
              ? Badge(
                  label: Text('$cartBadgeCount'),
                  child: Image.asset('assets/icons/customer/cart_active.png', width: 24, height: 24),
                )
              : Image.asset('assets/icons/customer/cart_active.png', width: 24, height: 24),
          activeIcon: cartBadgeCount > 0
              ? Badge(
                  label: Text('$cartBadgeCount'),
                  child: Image.asset('assets/icons/customer/cart_inactive.png', width: 24, height: 24),
                )
              : Image.asset('assets/icons/customer/cart_inactive.png', width: 24, height: 24),
          label: '장바구니',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/customer/contract_inactive.png', width: 24, height: 24),
          activeIcon: Image.asset('assets/icons/customer/contract_active.png', width: 24, height: 24),
          label: '계약함',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/customer/mypage_inactive.png', width: 24, height: 24),
          activeIcon: Image.asset('assets/icons/customer/mypage_active.png', width: 24, height: 24),
          label: '마이페이지',
        ),
      ],
    );
  }

  // 업체용 탭바 (2탭: 홈, 마이페이지) — 2차 디자인 아이콘 적용
  factory AppTabBar.vendor({
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return AppTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/vendor/home_inactive.png', width: 24, height: 24),
          activeIcon: Image.asset('assets/icons/vendor/home_active.png', width: 24, height: 24),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/icons/vendor/mypage_inactive.png', width: 24, height: 24),
          activeIcon: Image.asset('assets/icons/vendor/mypage_active.png', width: 24, height: 24),
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
