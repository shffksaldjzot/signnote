import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================
// 성공 애니메이션 위젯
// 초록색 원 + 체크마크 그리기 애니메이션
// 다이얼로그에서 완료/성공 상태를 시각적으로 표현
// ============================================

/// 성공 체크마크 애니메이션 위젯
///
/// 초록색 원이 확대된 후, 체크마크가 그려지는 애니메이션
/// 주로 계약 완료, 저장 성공 등의 상황에서 사용
///
/// [size] - 원의 크기 (기본값: 80)
/// [color] - 원과 체크마크 색상 (기본값: AppColors.success #4CAF50)
/// [onComplete] - 애니메이션 완료 시 호출되는 콜백
class SuccessAnimation extends StatefulWidget {
  /// 애니메이션 원의 크기 (가로/세로)
  final double size;

  /// 원과 체크마크 색상
  final Color color;

  /// 애니메이션 완료 후 실행할 콜백 (선택)
  final VoidCallback? onComplete;

  const SuccessAnimation({
    super.key,
    this.size = 80,
    this.color = const Color(0xFF4CAF50),
    this.onComplete,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  // 전체 애니메이션을 제어하는 컨트롤러 (600ms)
  late final AnimationController _controller;

  // 1단계: 원이 커지는 애니메이션 (0% ~ 40%)
  late final Animation<double> _circleScaleAnimation;

  // 2단계: 체크마크가 그려지는 애니메이션 (40% ~ 100%)
  late final Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 원 확대 애니메이션: 0 → 1 (전체 시간의 0% ~ 40%)
    _circleScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        // 전체 600ms 중 처음 40% (0~240ms) 구간
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // 체크마크 그리기 애니메이션: 0 → 1 (전체 시간의 40% ~ 100%)
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        // 전체 600ms 중 40%~100% (240~600ms) 구간
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    // 애니메이션 완료 시 콜백 호출
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    // 위젯 생성 즉시 애니메이션 시작
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            // 원 확대 애니메이션 적용
            scale: _circleScaleAnimation.value,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _CheckPainter(
                color: widget.color,
                // 체크마크 그리기 진행률 전달
                checkProgress: _checkAnimation.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 체크마크를 그리는 CustomPainter
///
/// 원 배경 위에 체크마크(✓) 경로를 [checkProgress] 비율만큼 그림
class _CheckPainter extends CustomPainter {
  /// 원과 체크마크 색상
  final Color color;

  /// 체크마크 그리기 진행률 (0.0 ~ 1.0)
  final double checkProgress;

  _CheckPainter({
    required this.color,
    required this.checkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // ── 1단계: 초록색 원 배경 그리기 ──
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, circlePaint);

    // ── 2단계: 흰색 체크마크 그리기 ──
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.08 // 크기에 비례하는 선 두께
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // 체크마크 경로의 세 꼭짓점 좌표 (중앙 기준 비율)
      final startPoint = Offset(size.width * 0.27, size.height * 0.50);
      final midPoint = Offset(size.width * 0.43, size.height * 0.65);
      final endPoint = Offset(size.width * 0.73, size.height * 0.35);

      final path = Path();

      // 체크마크의 첫 번째 획 (↘ 방향): 진행률 0 ~ 0.5
      if (checkProgress <= 0.5) {
        // 첫 번째 획만 부분적으로 그리기
        final firstSegmentProgress = checkProgress / 0.5;
        final currentPoint = Offset(
          startPoint.dx + (midPoint.dx - startPoint.dx) * firstSegmentProgress,
          startPoint.dy + (midPoint.dy - startPoint.dy) * firstSegmentProgress,
        );
        path.moveTo(startPoint.dx, startPoint.dy);
        path.lineTo(currentPoint.dx, currentPoint.dy);
      } else {
        // 첫 번째 획 완성 + 두 번째 획 (↗ 방향) 부분적으로 그리기
        final secondSegmentProgress = (checkProgress - 0.5) / 0.5;
        final currentPoint = Offset(
          midPoint.dx + (endPoint.dx - midPoint.dx) * secondSegmentProgress,
          midPoint.dy + (endPoint.dy - midPoint.dy) * secondSegmentProgress,
        );
        path.moveTo(startPoint.dx, startPoint.dy);
        path.lineTo(midPoint.dx, midPoint.dy);
        path.lineTo(currentPoint.dx, currentPoint.dy);
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) {
    // 진행률이나 색상이 바뀌었을 때만 다시 그리기
    return oldDelegate.checkProgress != checkProgress ||
        oldDelegate.color != color;
  }
}

// ============================================
// 성공 다이얼로그 헬퍼 함수
// ============================================

/// 성공 애니메이션이 포함된 다이얼로그를 표시
///
/// [context] - 빌드 컨텍스트
/// [message] - 다이얼로그에 표시할 메시지
/// [onConfirm] - "확인" 버튼 클릭 시 실행할 콜백 (선택)
///
/// 사용 예시:
/// ```dart
/// await showSuccessDialog(context, '계약이 완료되었습니다.');
/// ```
Future<void> showSuccessDialog(
  BuildContext context,
  String message, {
  VoidCallback? onConfirm,
}) {
  return showDialog<void>(
    context: context,
    // 바깥 영역 터치로 닫기 방지
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        // 다이얼로그 둥근 모서리 (앱 테마와 일치)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 성공 체크마크 애니메이션
            const SuccessAnimation(size: 80),
            const SizedBox(height: 24),
            // 성공 메시지
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF000000),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // "확인" 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onConfirm?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
