import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/auth_service.dart';

// ============================================
// 스플래시 화면 (앱 시작 시 로고 표시)
//
// 앱을 켜면 가장 먼저 보이는 화면.
// 로고를 2초간 보여준 뒤 로그인 여부에 따라:
// - 로그인 O → 참여코드 입장 화면
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

  // 로그인 상태에 따라 다음 화면 결정
  Future<void> _navigateNext() async {
    if (!mounted) return;

    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // 로그인 되어 있으면 → 참여코드 입장 화면
      context.go(AppRoutes.entryCode);
    } else {
      // 로그인 안 되어 있으면 → 로그인 화면
      context.go(AppRoutes.login);
    }
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
