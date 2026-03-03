// Signnote 앱 기본 테스트
// 앱이 정상적으로 실행되는지 확인하는 테스트

import 'package:flutter_test/flutter_test.dart';
import 'package:signnote_app/main.dart';

void main() {
  testWidgets('로그인 화면이 정상적으로 표시되는지 확인', (WidgetTester tester) async {
    // 앱 빌드
    await tester.pumpWidget(const SignnoteApp());

    // 로그인 화면의 핵심 요소가 표시되는지 확인
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
  });
}
