import 'package:flutter/material.dart';

// ============================================
// 스켈레톤 로딩 위젯 (시머 효과)
// 외부 패키지 없이 AnimationController + LinearGradient로 구현
// 데이터 로딩 중 빈 화면 대신 카드 형태의 시머 효과를 표시
// ============================================

/// 시머(빛 반짝임) 효과가 적용된 기본 위젯
///
/// 자식 위젯을 감싸서 로딩 중 시머 애니메이션을 보여줌
/// 직접 사용하기보다 [SkeletonCard], [SkeletonList]를 사용 권장
class ShimmerEffect extends StatefulWidget {
  /// 시머 효과를 적용할 자식 위젯
  final Widget child;

  const ShimmerEffect({
    super.key,
    required this.child,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  // 시머 애니메이션을 제어하는 컨트롤러
  late final AnimationController _controller;

  // 시머 색상 정의
  static const Color _baseColor = Color(0xFFE0E0E0); // 기본 회색
  static const Color _highlightColor = Color(0xFFF5F5F5); // 밝은 하이라이트

  @override
  void initState() {
    super.initState();
    // 1.5초 주기로 무한 반복하는 애니메이션 설정
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
        return ShaderMask(
          // 블렌드 모드: 시머 그라데이션을 자식 위젯에 덮어씌움
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              // 왼쪽에서 오른쪽으로 이동하는 그라데이션
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                _baseColor,
                _highlightColor,
                _baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              // 애니메이션 값에 따라 그라데이션 위치 이동 (-1 → 2)
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 그라데이션을 수평으로 슬라이딩시키는 변환 클래스
class _SlidingGradientTransform extends GradientTransform {
  /// 슬라이드 진행률 (0.0 ~ 1.0)
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // 그라데이션을 좌→우로 3배 너비만큼 이동 (자연스러운 흐름)
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 3 - 1),
      0.0,
      0.0,
    );
  }
}

/// 스켈레톤 카드 위젯
///
/// 실제 콘텐츠 카드와 유사한 형태의 로딩 플레이스홀더
///
/// [height] - 카드 높이 (기본값: 120)
/// [borderRadius] - 모서리 둥글기 (기본값: 12)
/// [padding] - 외부 여백
class SkeletonCard extends StatelessWidget {
  /// 카드의 높이
  final double height;

  /// 모서리 둥글기 반경
  final double borderRadius;

  /// 카드의 외부 여백
  final EdgeInsetsGeometry padding;

  const SkeletonCard({
    super.key,
    this.height = 120,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ShimmerEffect(
        child: Container(
          height: height,
          decoration: BoxDecoration(
            // 둥근 모서리 사각형 형태
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 제목 영역 (너비 60%)
                Container(
                  height: 16,
                  width: double.infinity * 0.6,
                  constraints: const BoxConstraints(maxWidth: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // 중간 설명 영역 (너비 80%)
                Container(
                  height: 12,
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // 하단 보조 텍스트 영역 (너비 40%)
                Container(
                  height: 12,
                  constraints: const BoxConstraints(maxWidth: 120),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
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

/// 스켈레톤 리스트 위젯
///
/// 여러 개의 [SkeletonCard]를 세로로 나열하여 리스트 로딩 상태를 표현
///
/// [itemCount] - 표시할 스켈레톤 카드 수 (기본값: 5)
/// [itemHeight] - 개별 카드 높이 (기본값: 120)
class SkeletonList extends StatelessWidget {
  /// 표시할 스켈레톤 카드 개수
  final int itemCount;

  /// 개별 카드의 높이
  final double itemHeight;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // 스크롤 비활성화 (부모 스크롤뷰 안에서 사용 시)
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return SkeletonCard(height: itemHeight);
      },
    );
  }
}
