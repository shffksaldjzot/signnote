import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'config/app_router.dart';

// ============================================
// Signnote 앱의 시작점 (진입점)
// 앱을 실행하면 가장 먼저 이 파일이 실행됩니다
//
// 화면 타입 규칙:
// - 관리자(ADMIN): PC 웹 대시보드 (전체 너비, 좌측 사이드바)
// - 주관사/업체/고객: 모바일 화면 (430px 고정)
// GoRouter를 사용하여 웹 브라우저 주소창으로도 화면 이동 가능
// ============================================

void main() {
  runApp(const SignnoteApp());
}

/// Signnote 앱의 최상위 위젯 (앱 전체를 감싸는 껍데기)
class SignnoteApp extends StatelessWidget {
  const SignnoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,          // 앱 이름: Signnote
      theme: AppTheme.lightTheme,           // 테마 적용 (색상, 글꼴 등)
      debugShowCheckedModeBanner: false,    // 오른쪽 위 DEBUG 띠 숨기기
      routerConfig: appRouter,              // GoRouter 라우터 연결

      // 관리자 대시보드(/organizer/dashboard 등)는 전체 너비 사용
      // 나머지 화면은 모바일 사이즈(430px)로 가운데 고정
      builder: (context, child) {
        // ValueListenableBuilder로 경로 변경 감지 (화면 이동 시 자동 업데이트)
        return ValueListenableBuilder<RouteInformation>(
          valueListenable: appRouter.routeInformationProvider,
          child: child, // 라우터 출력 (현재 화면)
          builder: (context, routeInfo, routerChild) {
            final path = routeInfo.uri.path;

            // 관리자 대시보드 경로(/admin/*)면 전체 너비 (430px 제한 없음)
            final bool isAdminDashboard = path.startsWith('/admin/');

            if (isAdminDashboard) {
              // 관리자: 전체 화면 사용 (PC 대시보드)
              return Container(
                color: Colors.white,
                child: routerChild,
              );
            }

            // 주관사/업체/고객: 모바일 사이즈(430px)로 가운데 표시
            return Container(
              color: const Color(0xFFF5F5F5),  // 바깥 배경색 (연한 회색)
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),  // 모바일 너비 고정
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // PC에서 좌우에 살짝 그림자 효과
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: routerChild,
                  ),
                ),
              ),
            );
          },
        );
      },

      // 한국어 날짜 선택기 등이 정상 동작하도록 로컬라이제이션 설정
      locale: const Locale('ko'),
      supportedLocales: const [
        Locale('ko'),  // 한국어
        Locale('en'),  // 영어 (기본)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,    // 날짜 선택기 등 Material 위젯 한국어
        GlobalWidgetsLocalizations.delegate,     // 기본 위젯 방향 (좌→우)
        GlobalCupertinoLocalizations.delegate,   // iOS 스타일 위젯 한국어
      ],
    );
  }
}
