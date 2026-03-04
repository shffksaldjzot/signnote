import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../widgets/common/app_button.dart';
import '../../services/auth_service.dart';
import '../customer/home_screen.dart';
import '../vendor/home_screen.dart';
import '../organizer/home_screen.dart';

// ============================================
// 참여 코드 입장 화면 (Entry Code Screen)
//
// 디자인 참고: 1.고객용-첫 페이지.jpg, 1.업체용-첫 페이지.jpg
// - Signnote 로고 (+ 역할 뱃지)
// - "안녕하세요. 사인노트 사용을 위해 행사 참여 코드를 입력해 주세요."
// - 6칸 코드 입력
// - "입장하기" 버튼 (고객: 파란색, 업체: 검정색)
// - 하단에 마이페이지 아이콘
// ============================================

class EntryCodeScreen extends StatefulWidget {
  final String role;  // 사용자 역할 (CUSTOMER, VENDOR, ORGANIZER)

  const EntryCodeScreen({
    super.key,
    required this.role,
  });

  @override
  State<EntryCodeScreen> createState() => _EntryCodeScreenState();
}

class _EntryCodeScreenState extends State<EntryCodeScreen> {
  // 각 칸의 입력 컨트롤러 (6칸)
  final List<TextEditingController> _controllers = List.generate(
    AppConstants.entryCodeLength,
    (_) => TextEditingController(),
  );
  // 각 칸의 포커스 (어느 칸이 활성화되었는지)
  final List<FocusNode> _focusNodes = List.generate(
    AppConstants.entryCodeLength,
    (_) => FocusNode(),
  );
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // 입력된 6자리 코드 합치기
  String get _entryCode {
    return _controllers.map((c) => c.text).join();
  }

  // 입장하기 버튼 눌렀을 때 — 실제 API 호출
  Future<void> _handleEnter() async {
    if (_entryCode.length < AppConstants.entryCodeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참여 코드 6자리를 모두 입력해 주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // AuthService를 통해 실제 API 호출
    final result = await _authService.enterEvent(_entryCode);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('행사에 입장합니다!')),
      );

      // 역할별 홈 화면으로 이동 (기존 화면 스택 모두 제거)
      Widget homeScreen;
      switch (widget.role) {
        case AppConstants.roleVendor:
          homeScreen = const VendorHomeScreen();
          break;
        case AppConstants.roleOrganizer:
          homeScreen = const OrganizerHomeScreen();
          break;
        default: // CUSTOMER
          homeScreen = const CustomerHomeScreen();
          break;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => homeScreen),
        (route) => false, // 모든 이전 화면 제거
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '유효하지 않은 참여 코드입니다')),
      );
    }
  }

  // 역할에 따른 뱃지 텍스트
  String get _roleBadgeText {
    switch (widget.role) {
      case AppConstants.roleVendor:
        return '협력업체';
      case AppConstants.roleOrganizer:
        return '주관사';
      default:
        return '';  // 고객은 뱃지 없음
    }
  }

  @override
  Widget build(BuildContext context) {
    // 고객은 파란 버튼, 업체/주관사는 검정 버튼
    final isCustomer = widget.role == AppConstants.roleCustomer;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // 로고 + 역할 뱃지 (진짜 logo.png 이미지 사용)
              Row(
                children: [
                  // 진짜 로고 이미지 파일 사용
                  Image.asset(
                    'assets/images/logo.png',
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  // 역할 뱃지 (업체/주관사만 표시)
                  if (_roleBadgeText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _roleBadgeText,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // 안내 메시지
              const Text(
                '안녕하세요.\n사인노트 사용을 위해\n행사 참여 코드를 입력해 주세요.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),

              // 6칸 코드 입력 (화면 중간에 배치)
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  AppConstants.entryCodeLength,
                  (index) => _buildCodeBox(index),
                ),
              ),
              const Spacer(),

              // 입장하기 버튼
              isCustomer
                  ? AppButton(
                      text: '입장하기',
                      onPressed: _handleEnter,
                      isLoading: _isLoading,
                    )
                  : AppButton.black(
                      text: '입장하기',
                      onPressed: _handleEnter,
                      isLoading: _isLoading,
                    ),
              const SizedBox(height: 16),
              // 로그아웃 버튼 (다른 계정으로 전환할 수 있게)
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await _authService.logout();
                    if (!mounted) return;
                    context.go(AppRoutes.login);
                  },
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('로그아웃'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 코드 입력 칸 하나 만들기
  Widget _buildCodeBox(int index) {
    return Container(
      width: 48,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,  // 숫자 키패드만 표시
        maxLength: 1,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          counterText: '',  // 글자수 표시 숨기기
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        // 한 글자 입력하면 자동으로 다음 칸으로 이동
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,  // 숫자만 입력 가능
        ],
        onChanged: (value) {
          if (value.isNotEmpty && index < AppConstants.entryCodeLength - 1) {
            _focusNodes[index + 1].requestFocus();
          }
          // 마지막 칸이면 키보드 닫기
          if (value.isNotEmpty && index == AppConstants.entryCodeLength - 1) {
            _focusNodes[index].unfocus();
          }
        },
      ),
    );
  }
}
