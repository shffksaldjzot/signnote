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

// 탭 아이템 데이터 (아이콘 이미지 경로 + 라벨 + 뱃지)
class TabItemData {
  final String activeIcon;    // 활성 아이콘 경로
  final String inactiveIcon;  // 비활성 아이콘 경로
  final String label;         // 탭 이름
  final int badgeCount;       // 뱃지 숫자 (0이면 없음)

  const TabItemData({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

class AppTabBar extends StatefulWidget {
  final int currentIndex;                    // 현재 선택된 탭 번호 (0부터)
  final ValueChanged<int> onTap;             // 탭 눌렀을 때 실행할 동작
  final List<TabItemData> tabItems;         // 탭 아이템 데이터 목록

  const AppTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.tabItems,
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
      tabItems: [
        const TabItemData(
          activeIcon: 'assets/icons/customer/home_active.png',
          inactiveIcon: 'assets/icons/customer/home_inactive.png',
          label: '홈',
        ),
        // 장바구니 아이콘 (파일명이 뒤바뀌어있어서 active↔inactive 교차 사용)
        TabItemData(
          activeIcon: 'assets/icons/customer/cart_inactive.png',
          inactiveIcon: 'assets/icons/customer/cart_active.png',
          label: '장바구니',
          badgeCount: cartBadgeCount,
        ),
        const TabItemData(
          activeIcon: 'assets/icons/customer/contract_active.png',
          inactiveIcon: 'assets/icons/customer/contract_inactive.png',
          label: '계약함',
        ),
        const TabItemData(
          activeIcon: 'assets/icons/customer/mypage_active.png',
          inactiveIcon: 'assets/icons/customer/mypage_inactive.png',
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
      tabItems: const [
        TabItemData(
          activeIcon: 'assets/icons/vendor/home_active.png',
          inactiveIcon: 'assets/icons/vendor/home_inactive.png',
          label: '홈',
        ),
        TabItemData(
          activeIcon: 'assets/icons/vendor/mypage_active.png',
          inactiveIcon: 'assets/icons/vendor/mypage_inactive.png',
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
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar> with TickerProviderStateMixin {
  // 각 탭별 바운스 애니메이션 컨트롤러
  late List<AnimationController> _bounceControllers;
  // 각 탭별 스케일 애니메이션 (1.0 → 1.2 → 1.0 탄성 효과)
  late List<Animation<double>> _scaleAnimations;
  // 이전 선택 탭 인덱스 (탭이 변경될 때만 바운스 발동)
  int _previousIndex = -1;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _initAnimations();
  }

  // 애니메이션 컨트롤러 초기화
  void _initAnimations() {
    _bounceControllers = List.generate(
      widget.tabItems.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300), // 바운스 총 시간
      ),
    );
    _scaleAnimations = _bounceControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut, // 탄성(스프링) 커브
        ),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(covariant AppTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 탭 개수가 바뀌면 애니메이션 재생성
    if (oldWidget.tabItems.length != widget.tabItems.length) {
      _disposeAnimations();
      _initAnimations();
      _previousIndex = widget.currentIndex;
      return;
    }

    // 탭이 바뀌었을 때만 바운스 애니메이션 실행
    if (widget.currentIndex != _previousIndex) {
      _bounceControllers[widget.currentIndex].forward(from: 0.0);
      _previousIndex = widget.currentIndex;
    }
  }

  // 애니메이션 컨트롤러 해제
  void _disposeAnimations() {
    for (final controller in _bounceControllers) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  // 아이콘 위젯 생성 (뱃지 포함 여부 처리)
  Widget _buildIcon(String assetPath, int badgeCount) {
    final icon = Image.asset(assetPath, width: 24, height: 24);
    if (badgeCount > 0) {
      return Badge(
        label: Text('$badgeCount'),
        child: icon,
      );
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        // 상단 구분선 (BottomNavigationBar 기본 동작 유지)
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.tabItems.length, (index) {
              final item = widget.tabItems[index];
              final isActive = widget.currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 바운스 애니메이션 적용된 아이콘
                      AnimatedBuilder(
                        animation: _scaleAnimations[index],
                        builder: (context, child) {
                          return Transform.scale(
                            scale: isActive ? _scaleAnimations[index].value : 1.0,
                            child: child,
                          );
                        },
                        child: _buildIcon(
                          isActive ? item.activeIcon : item.inactiveIcon,
                          item.badgeCount,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 탭 라벨
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
