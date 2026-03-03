import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/common/app_button.dart';
import '../../services/auth_service.dart';
import 'entry_code_screen.dart';

// ============================================
// 회원가입 화면 (Register Screen)
//
// 디자인에는 별도 회원가입 화면이 없지만,
// 로그인 화면의 "회원가입" 버튼을 누르면 이 화면으로 이동
//
// 입력 항목:
//   - 이메일 (아이디)
//   - 비밀번호
//   - 비밀번호 확인
//   - 이름
//   - 전화번호
//   - 역할 선택 (고객 / 협력업체 / 주관사)
//   - 사업자번호 (업체만)
// ============================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNumberController = TextEditingController();

  final _authService = AuthService();  // 인증 API 서비스
  String _selectedRole = AppConstants.roleCustomer;  // 기본: 고객
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _businessNumberController.dispose();
    super.dispose();
  }

  // 회원가입 버튼 눌렀을 때
  Future<void> _handleRegister() async {
    // 입력값 검증
    if (_emailController.text.trim().isEmpty) {
      _showError('이메일을 입력해 주세요');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('비밀번호는 6자 이상이어야 합니다');
      return;
    }
    if (_passwordController.text != _passwordConfirmController.text) {
      _showError('비밀번호가 일치하지 않습니다');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showError('이름을 입력해 주세요');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('전화번호를 입력해 주세요');
      return;
    }

    setState(() => _isLoading = true);

    // 서버에 회원가입 요청
    final result = await _authService.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      businessNumber: _selectedRole == AppConstants.roleVendor
          ? _businessNumberController.text.trim()
          : null,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      // 회원가입 성공 → 참여 코드 입장 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => EntryCodeScreen(role: _selectedRole),
        ),
        (route) => false,  // 이전 화면 다 제거 (뒤로가기 방지)
      );
    } else {
      _showError(result['error'] ?? '회원가입에 실패했습니다');
    }
  }

  // 에러/안내 메시지 표시
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 업체(VENDOR)일 때만 사업자번호 입력 필드 표시
    final isVendor = _selectedRole == AppConstants.roleVendor;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '회원가입',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // 이메일
              const _SectionLabel(text: '이메일'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: '이메일을 입력해 주세요'),
              ),
              const SizedBox(height: 20),

              // 비밀번호
              const _SectionLabel(text: '비밀번호'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '비밀번호 (6자 이상)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordConfirmController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '비밀번호 확인'),
              ),
              const SizedBox(height: 20),

              // 이름
              const _SectionLabel(text: '이름'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: '이름을 입력해 주세요'),
              ),
              const SizedBox(height: 20),

              // 전화번호
              const _SectionLabel(text: '전화번호'),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '전화번호를 입력해 주세요'),
              ),
              const SizedBox(height: 20),

              // 역할 선택
              const _SectionLabel(text: '가입 유형'),
              const SizedBox(height: 8),
              _buildRoleSelector(),
              const SizedBox(height: 20),

              // 사업자번호 (업체만 표시)
              if (isVendor) ...[
                const _SectionLabel(text: '사업자번호'),
                const SizedBox(height: 8),
                TextField(
                  controller: _businessNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '사업자번호를 입력해 주세요'),
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 12),

              // 회원가입 버튼
              AppButton(
                text: '회원가입',
                onPressed: _handleRegister,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 역할 선택 위젯 (3개 칩 형태)
  Widget _buildRoleSelector() {
    final roles = [
      {'value': AppConstants.roleCustomer, 'label': '고객'},
      {'value': AppConstants.roleVendor, 'label': '협력업체'},
      {'value': AppConstants.roleOrganizer, 'label': '주관사'},
    ];

    return Row(
      children: roles.map((role) {
        final isSelected = _selectedRole == role['value'];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedRole = role['value']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textPrimary : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.textPrimary : AppColors.border,
                ),
              ),
              child: Text(
                role['label']!,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 섹션 라벨 (작은 위젯 - "이메일", "비밀번호" 같은 제목)
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
