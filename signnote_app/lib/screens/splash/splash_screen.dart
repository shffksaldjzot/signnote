import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/event_service.dart';

// ============================================
// 스플래시 화면 (앱 시작 시 로고 표시)
//
// 앱을 켜면 가장 먼저 보이는 화면.
// 로고를 2초간 보여준 뒤 자동로그인 처리:
// - 로그인 O + 주관사/관리자 → 주관사 홈 (PC/모바일 동일)
// - 로그인 O + 고객/업체 → 참여코드 입장 화면
// - 로그인 X → 로그인 화면
// ============================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // 페이드인 애니메이션 컨트롤러
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 0.8초에 걸쳐 로고가 서서히 나타남
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    // 2초 후 다음 화면으로 이동
    Future.delayed(const Duration(seconds: 2), _navigateNext);
  }

  // 자동로그인: 저장된 토큰과 사용자 정보로 역할별 홈 화면으로 이동
  Future<void> _navigateNext() async {
    if (!mounted) return;

    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // 저장된 사용자 정보에서 역할 가져오기
      final userInfo = await ApiService().getUserInfo();
      final role = userInfo?['role'] ?? '';

      if (!mounted) return;

      // 관리자 → PC 웹 대시보드 / 주관사 → 모바일 홈
      if (role == AppConstants.roleAdmin) {
        context.go(AppRoutes.organizerDashboard);
      } else if (role == AppConstants.roleOrganizer) {
        context.go(AppRoutes.organizerHome);
      } else if (role == AppConstants.roleVendor) {
        // 협력업체: 참여한 행사가 있으면 바로 홈, 없으면 행사코드 입력
        final hasEvents = await _checkHasParticipatingEvents();
        if (!mounted) return;
        if (hasEvents) {
          context.go(AppRoutes.vendorHome);
        } else {
          context.go(AppRoutes.entryCode, extra: role);
        }
      } else {
        // 고객: 참여한 행사가 있으면 바로 홈, 없으면 행사코드 입장
        final hasEvents = await _checkHasParticipatingEvents();
        if (!mounted) return;
        if (hasEvents) {
          context.go(AppRoutes.customerHome);
        } else {
          context.go(AppRoutes.entryCode, extra: role.isNotEmpty ? role : 'CUSTOMER');
        }
      }
    } else {
      // 로그인 안 되어 있으면 → 로그인 화면
      context.go(AppRoutes.login);
    }
  }

  // 협력업체가 참여한 행사가 있는지 확인
  Future<bool> _checkHasParticipatingEvents() async {
    try {
      final result = await EventService().getEvents();
      if (result['success'] == true) {
        final events = result['events'] as List? ?? [];
        return events.isNotEmpty;
      }
    } catch (_) {}
    return false;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 이미지
              Image.asset(
                'assets/images/logo.png',
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              // 앱 한글 이름
              const Text(
                '아파트 입주옵션 계약 플랫폼',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 48),
              // 로딩 표시
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
