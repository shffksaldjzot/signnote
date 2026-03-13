import 'package:flutter/material.dart';

// ============================================
// 화면 전환 애니메이션 유틸리티
// 페이드 + 슬라이드 업 트랜지션을 제공
// ============================================

/// 페이드 + 슬라이드 업 애니메이션으로 화면 전환하는 PageRoute 생성
///
/// [page] - 이동할 대상 화면 위젯
/// [duration] - 애니메이션 지속 시간 (기본값: 300ms)
///
/// 사용 예시:
/// ```dart
/// Navigator.push(context, fadeSlideRoute(MyScreen()));
/// ```
PageRouteBuilder<T> fadeSlideRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 300),
}) {
  return PageRouteBuilder<T>(
    // 대상 화면 위젯
    pageBuilder: (context, animation, secondaryAnimation) => page,
    // 애니메이션 지속 시간 설정
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    // 페이드 + 슬라이드 업 조합 애니메이션
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // 부드러운 감속 곡선 적용
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        // 투명도 0 → 1 (서서히 나타남)
        opacity: curvedAnimation,
        child: SlideTransition(
          // 아래에서 위로 슬라이드 (Y축 0.08 → 0)
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

/// Hero 애니메이션과 호환되는 페이드 + 슬라이드 업 PageRoute
///
/// Hero 위젯으로 감싼 요소가 있을 때 자연스러운 전환을 위해 사용
/// (예: 카드 → 상세 화면 연결 시)
///
/// [page] - 이동할 대상 화면 위젯
/// [duration] - 애니메이션 지속 시간 (기본값: 300ms)
///
/// 사용 예시:
/// ```dart
/// Navigator.push(context, heroFadeSlideRoute(DetailScreen(item: item)));
/// ```
PageRouteBuilder<T> heroFadeSlideRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 300),
}) {
  return PageRouteBuilder<T>(
    // 대상 화면 위젯
    pageBuilder: (context, animation, secondaryAnimation) => page,
    // 애니메이션 지속 시간 설정
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    // Hero 애니메이션이 동작하도록 opaque 유지
    opaque: true,
    // 페이드만 적용 (Hero 전환이 슬라이드 역할을 대체)
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: child,
      );
    },
  );
}
