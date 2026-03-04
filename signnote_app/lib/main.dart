import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'config/app_router.dart';

// ============================================
// Signnote 앱의 시작점 (진입점)
// 앱을 실행하면 가장 먼저 이 파일이 실행됩니다
//
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
