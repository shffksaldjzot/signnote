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
import '../screens/organizer/web/web_shell.dart';
import '../screens/organizer/web/dashboard_page.dart';
import '../screens/organizer/web/events_page.dart';
import '../screens/organizer/web/event_detail_page.dart';
import '../screens/organizer/web/contracts_page.dart';
import '../screens/organizer/web/products_page.dart';
import '../screens/organizer/web/users_page.dart';
import '../screens/organizer/web/settlements_page.dart';
import '../screens/organizer/web/logs_page.dart';
import '../screens/organizer/web/mypage_page.dart';

// ============================================
// GoRouter 라우터 설정
//
// 웹 브라우저에서 URL 주소로 화면 이동이 가능하게 해주는 설정.
// 예: /login → 로그인 화면, /organizer/dashboard → 대시보드
//
// ShellRoute: 사이드바는 고정하고 오른쪽 내용만 바꾸는 구조
// ============================================

// 네비게이터 키 (셸 내부 네비게이션용)
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter 인스턴스 (앱 전체에서 사용)
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',  // 첫 화면: 스플래시
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

    // ── 주관사 모바일 홈 ──
    GoRoute(
      path: AppRoutes.organizerHome,
      builder: (context, state) => const OrganizerHomeScreen(),
    ),

    // ── 주관사 PC 웹 대시보드 (사이드바 레이아웃) ──
    // ShellRoute: 사이드바는 고정, 오른쪽 콘텐츠만 변경
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return WebShell(child: child);  // 사이드바 + 콘텐츠 영역
      },
      routes: [
        // 대시보드 메인
        GoRoute(
          path: AppRoutes.organizerDashboard,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardPage(),
          ),
        ),
        // 행사 관리
        GoRoute(
          path: AppRoutes.organizerWebEvents,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: EventsPage(),
          ),
        ),
        // 행사 상세 (상품 + 계약)
        GoRoute(
          path: AppRoutes.organizerWebEventDetail,
          pageBuilder: (context, state) {
            final eventId = state.pathParameters['id'] ?? '';
            return NoTransitionPage(
              child: EventDetailPage(eventId: eventId),
            );
          },
        ),
        // 전체 계약 현황
        GoRoute(
          path: AppRoutes.organizerWebContracts,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ContractsPage(),
          ),
        ),
        // 품목 관리
        GoRoute(
          path: AppRoutes.organizerWebProducts,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProductsPage(),
          ),
        ),
        // 사용자 관리
        GoRoute(
          path: AppRoutes.organizerWebUsers,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: UsersPage(),
          ),
        ),
        // 정산 관리
        GoRoute(
          path: AppRoutes.organizerWebSettlements,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettlementsPage(),
          ),
        ),
        // 활동 로그
        GoRoute(
          path: AppRoutes.organizerWebLogs,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LogsPage(),
          ),
        ),
        // 마이페이지 (비밀번호 변경)
        GoRoute(
          path: AppRoutes.organizerWebMypage,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MypagePage(),
          ),
        ),
      ],
    ),
  ],
);
