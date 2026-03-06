import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../widgets/common/app_button.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import 'register_screen.dart';

// ============================================
// 로그인 화면 (Login Screen)
//
// 디자인 참고: login.jpg
// - Signnote 로고
// - "안녕하세요. 사인노트 사용을 위해 로그인 및 회원가입을 해주세요."
// - 아이디(이메일) 입력
// - 비밀번호 입력
// - 파란 "로그인" 버튼
// - 검정 "회원가입" 버튼
//
// 로그인 후 분기:
//   - 주관사/관리자 → 바로 주관사 홈 (PC/모바일 동일)
//   - 고객/업체 → 참여 코드 입력 화면
//   - 미승인 업체/주관사 → 에러 메시지 (서버에서 403 반환)
// ============================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 입력값 컨트롤러 (사용자가 입력한 값을 가져오기 위해)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();  // 인증 API 서비스
  bool _isLoading = false;  // 로딩 중인지

  @override
  void dispose() {
    // 화면 종료 시 컨트롤러 정리 (메모리 누수 방지)
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 로그인 버튼 눌렀을 때
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 빈칸 체크
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력해 주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 서버에 로그인 요청
    final result = await _authService.login(email, password);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      // 로그인 성공 → 역할 + 화면 크기에 따라 분기
      final user = result['user'];
      final role = user['role'] ?? AppConstants.roleCustomer;

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
        // 고객: 참여한 행사가 있으면 바로 홈, 없으면 행사코드 입력
        final hasEvents = await _checkHasParticipatingEvents();
        if (!mounted) return;
        if (hasEvents) {
          context.go(AppRoutes.customerHome);
        } else {
          context.go(AppRoutes.entryCode, extra: role.isNotEmpty ? role : 'CUSTOMER');
        }
      }
    } else {
      // 로그인 실패 → 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '로그인에 실패했습니다')),
      );
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

  // 회원가입 버튼 눌렀을 때 → 회원가입 화면으로 이동
  void _handleRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Signnote 로고 (진짜 logo.png 이미지 사용)
              Image.asset(
                'assets/images/logo.png',
                height: 32,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),

              // 환영 메시지
              const Text(
                '안녕하세요.\n사인노트 사용을 위해\n로그인 및 회원가입을 해주세요.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,  // 줄 간격
                ),
              ),
              const SizedBox(height: 48),

              // 아이디(이메일) 입력 필드
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: '아이디',
                ),
              ),
              const SizedBox(height: 16),

              // 비밀번호 입력 필드
              TextField(
                controller: _passwordController,
                obscureText: true,     // 비밀번호 숨기기 (●●●●)
                decoration: const InputDecoration(
                  hintText: '비밀번호',
                ),
                // 엔터키로 로그인 실행
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 8),

              // 비밀번호를 잊으셨나요? 버튼 (기능은 추후 이메일 인증으로 구현 예정)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('비밀번호 찾기 기능은 준비중입니다')),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 로그인 버튼 (파란색)
              AppButton(
                text: '로그인',
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 12),

              // 회원가입 버튼 (검정색)
              AppButton.black(
                text: '회원가입',
                onPressed: _handleRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
