import 'package:flutter/material.dart';

// ============================================
// 애니메이션 리스트 아이템 위젯
// 리스트 항목이 순차적으로 페이드인 + 슬라이드 업 되는 효과
// index 값에 따라 100ms씩 시차를 두고 등장
// ============================================

/// 리스트 항목에 페이드인 + 슬라이드 업 애니메이션을 적용하는 래퍼 위젯
///
/// [index]에 따라 등장 시점이 순차적으로 지연되어
/// 리스트가 위에서부터 차례대로 나타나는 자연스러운 효과를 줌
///
/// 사용 예시:
/// ```dart
/// ListView.builder(
///   itemCount: items.length,
///   itemBuilder: (context, index) {
///     return AnimatedListItem(
///       index: index,
///       child: MyCard(item: items[index]),
///     );
///   },
/// )
/// ```
class AnimatedListItem extends StatefulWidget {
  /// 감쌀 자식 위젯 (실제 리스트 항목)
  final Widget child;

  /// 리스트에서의 순서 (0부터 시작, 지연 시간 계산에 사용)
  final int index;

  /// 개별 항목의 애니메이션 지속 시간 (기본값: 400ms)
  final Duration duration;

  /// 항목 간 애니메이션 시차 (기본값: 100ms)
  final Duration staggerDelay;

  /// 아래에서 위로 슬라이드되는 거리 (기본값: 30px)
  final double slideOffset;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 400),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.slideOffset = 30.0,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  // 애니메이션 컨트롤러
  late final AnimationController _controller;

  // 투명도 애니메이션 (0 → 1)
  late final Animation<double> _fadeAnimation;

  // 슬라이드 애니메이션 (아래 → 원래 위치)
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 부드러운 감속 곡선 적용
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // 페이드인 애니메이션: 투명 → 불투명
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);

    // 슬라이드 업 애니메이션: slideOffset만큼 아래에서 → 원래 위치로
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(curvedAnimation);

    // index에 따라 시차를 두고 애니메이션 시작
    // (최대 10개까지만 시차 적용, 그 이상은 동시 시작)
    final delayIndex = widget.index.clamp(0, 10);
    final delay = widget.staggerDelay * delayIndex;

    Future.delayed(delay, () {
      // 위젯이 아직 마운트되어 있을 때만 애니메이션 시작
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          // 페이드인 효과
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            // 슬라이드 업 효과
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
