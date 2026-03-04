import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/login_screen.dart';
import '../screens/onboarding/register_screen.dart';
import '../screens/onboarding/entry_code_screen.dart';
import '../screens/common/mypage_screen.dart';
import '../screens/common/notification_screen.dart';
import '../screens/organizer/home_screen.dart';

// ============================================
// GoRouter 라우터 설정
//
// 웹 브라우저에서 URL 주소로 화면 이동이 가능하게 해주는 설정.
// PC/모바일 모두 동일한 모바일 화면을 표시합니다.
// ============================================

// 네비게이터 키
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter 인스턴스 (앱 전체에서 사용)
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',  // 첫 화면: 스플래시
  // 웹 대시보드 URL로 직접 접속한 경우 → 모바일 홈으로 보내기
  redirect: (context, state) {
    final path = state.uri.path;
    if (path.startsWith('/organizer/') && path != AppRoutes.organizerHome) {
      return AppRoutes.organizerHome;
    }
    return null;
  },
  routes: [
    // ── 스플래시 화면 (앱 시작) ──
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    // ── 인증 관련 (로그인, 회원가입, 참여코드) ──
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.entryCode,
      builder: (context, state) {
        // 역할 정보를 extra로 전달받음
        final role = state.extra as String? ?? 'CUSTOMER';
        return EntryCodeScreen(role: role);
      },
    ),

    // ── 알림 화면 (공통) ──
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationScreen(),
    ),

    // ── 마이페이지 (공통) ──
    GoRoute(
      path: AppRoutes.mypage,
      builder: (context, state) {
        final role = state.extra as String? ?? 'CUSTOMER';
        return MypageScreen(role: role);
      },
    ),

    // ── 주관사 홈 (PC/모바일 동일한 화면) ──
    GoRoute(
      path: AppRoutes.organizerHome,
      builder: (context, state) => const OrganizerHomeScreen(),
    ),
  ],
);
