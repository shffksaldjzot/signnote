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
import '../screens/vendor/home_screen.dart';
import '../screens/customer/home_screen.dart';
// 관리자 PC 웹 대시보드 페이지들
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
// 역할별 화면 분기:
// - 관리자(ADMIN): PC 웹 대시보드 (WebShell + 좌측 사이드바)
// - 주관사(ORGANIZER): 모바일 화면 (430px)
// - 고객/업체: 모바일 화면 (430px)
// ============================================

// 네비게이터 키
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

    // ── 마이페이지 (공통 모바일) ──
    GoRoute(
      path: AppRoutes.mypage,
      builder: (context, state) {
        final role = state.extra as String? ?? 'CUSTOMER';
        return MypageScreen(role: role);
      },
    ),

    // ── 업체 모바일 홈 (VENDOR 전용) ──
    GoRoute(
      path: AppRoutes.vendorHome,
      builder: (context, state) => const VendorHomeScreen(),
    ),

    // ── 고객 모바일 홈 (CUSTOMER 전용) ──
    GoRoute(
      path: AppRoutes.customerHome,
      builder: (context, state) => const CustomerHomeScreen(),
    ),

    // ── 주관사 모바일 홈 (ORGANIZER 전용) ──
    GoRoute(
      path: AppRoutes.organizerHome,
      builder: (context, state) => const OrganizerHomeScreen(),
    ),

    // ── 관리자 PC 웹 대시보드 (ADMIN 전용) ──
    // ShellRoute로 WebShell(사이드바) 안에 각 페이지 표시
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => WebShell(child: child),
      routes: [
        // 대시보드
        GoRoute(
          path: AppRoutes.organizerDashboard,
          builder: (context, state) => const DashboardPage(),
        ),
        // 행사 관리
        GoRoute(
          path: AppRoutes.organizerWebEvents,
          builder: (context, state) => const EventsPage(),
        ),
        // 행사 상세
        GoRoute(
          path: AppRoutes.organizerWebEventDetail,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return EventDetailPage(eventId: id);
          },
        ),
        // 계약 현황
        GoRoute(
          path: AppRoutes.organizerWebContracts,
          builder: (context, state) => const ContractsPage(),
        ),
        // 품목 관리
        GoRoute(
          path: AppRoutes.organizerWebProducts,
          builder: (context, state) => const ProductsPage(),
        ),
        // 파트너 관리
        GoRoute(
          path: AppRoutes.organizerWebUsers,
          builder: (context, state) => const UsersPage(),
        ),
        // 정산 관리
        GoRoute(
          path: AppRoutes.organizerWebSettlements,
          builder: (context, state) => const SettlementsPage(),
        ),
        // 활동 로그 (관리자 전용)
        GoRoute(
          path: AppRoutes.organizerWebLogs,
          builder: (context, state) => const LogsPage(),
        ),
        // 마이페이지 (웹)
        GoRoute(
          path: AppRoutes.organizerWebMypage,
          builder: (context, state) => const MypagePage(),
        ),
      ],
    ),
  ],
);
