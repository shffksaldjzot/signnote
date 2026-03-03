import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'screens/onboarding/login_screen.dart';

// ============================================
// Signnote 앱의 시작점 (진입점)
// 앱을 실행하면 가장 먼저 이 파일이 실행됩니다
// ============================================

void main() {
  runApp(const SignnoteApp());
}

/// Signnote 앱의 최상위 위젯 (앱 전체를 감싸는 껍데기)
class SignnoteApp extends StatelessWidget {
  const SignnoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,          // 앱 이름: Signnote
      theme: AppTheme.lightTheme,           // 테마 적용 (색상, 글꼴 등)
      debugShowCheckedModeBanner: false,    // 오른쪽 위 DEBUG 띠 숨기기
      home: const LoginScreen(),             // 첫 화면: 로그인
    );
  }
}
