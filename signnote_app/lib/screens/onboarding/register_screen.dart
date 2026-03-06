import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/common/app_button.dart';
import '../../services/auth_service.dart';
import 'entry_code_screen.dart';
import 'login_screen.dart';
import '../organizer/home_screen.dart';

// ============================================
// 회원가입 화면 (Register Screen)
//
// 필드 순서:
//   1. 가입 유형 선택 (고객 / 협력업체 / 주관사) ← 맨 위
//   2. 이메일
//   3. 비밀번호 / 비밀번호 확인
//   4. 이름 (고객) 또는 업체명 (협력업체/주관사)
//   5. 전화번호 (010-0000-0000 형식)
//   6. 사업자등록번호 (협력업체/주관사, 000-00-00000 형식)
//   7. 사업자등록증 이미지 첨부 (협력업체/주관사)
//
// 협력업체/주관사는 관리자 승인 후 로그인 가능
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
  final _representativeNameController = TextEditingController(); // 대표자 성명
  final _phoneController = TextEditingController();
  final _businessNumberController = TextEditingController();
  final _businessAddressController = TextEditingController(); // 사업장 주소

  final _authService = AuthService();  // 인증 API 서비스
  String _selectedRole = AppConstants.roleCustomer;  // 기본: 고객
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _representativeNameController.dispose();
    _phoneController.dispose();
    _businessNumberController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  // 협력업체 또는 주관사인지 확인
  bool get _isBusinessRole =>
      _selectedRole == AppConstants.roleVendor ||
      _selectedRole == AppConstants.roleOrganizer;

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
      _showError(_isBusinessRole ? '업체명을 입력해 주세요' : '이름을 입력해 주세요');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('전화번호를 입력해 주세요');
      return;
    }
    // 협력업체/주관사는 사업자등록번호 필수
    if (_isBusinessRole && _businessNumberController.text.trim().isEmpty) {
      _showError('사업자등록번호를 입력해 주세요');
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
      representativeName: _isBusinessRole
          ? _representativeNameController.text.trim()
          : null,
      businessNumber: _isBusinessRole
          ? _businessNumberController.text.trim()
          : null,
      businessAddress: _isBusinessRole
          ? _businessAddressController.text.trim()
          : null,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'];
      final isApproved = user?['isApproved'] ?? true;

      if (!isApproved) {
        // 협력업체/주관사 → 승인 대기 안내 후 로그인 화면으로
        _showApprovalPendingDialog();
      } else if (_selectedRole == AppConstants.roleOrganizer) {
        // 주관사 (승인된 경우) → 바로 주관사 홈으로
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OrganizerHomeScreen()),
          (route) => false,
        );
      } else {
        // 고객 → 참여 코드 입장 화면으로 이동
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EntryCodeScreen(role: _selectedRole),
          ),
          (route) => false,
        );
      }
    } else {
      _showError(result['error'] ?? '회원가입에 실패했습니다');
    }
  }

  // 승인 대기 안내 다이얼로그 (브랜드 디자인 적용)
  void _showApprovalPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 체크 아이콘
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              '가입 신청 완료',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              '회원가입 신청이 완료되었습니다.\n관리자 승인 후 로그인할 수 있습니다.\n승인까지 잠시 기다려 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),
            // 확인 버튼 (브랜드 색상)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 에러/안내 메시지 표시
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
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

              // ──────── 1. 가입 유형 (맨 위) ────────
              const _SectionLabel(text: '가입 유형'),
              const SizedBox(height: 8),
              _buildRoleSelector(),
              const SizedBox(height: 20),

              // ──────── 2. 이메일 ────────
              const _SectionLabel(text: '이메일'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: '이메일을 입력해 주세요'),
              ),
              const SizedBox(height: 20),

              // ──────── 3. 비밀번호 ────────
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

              // ──────── 4. 이름 또는 업체명 ────────
              _SectionLabel(text: _isBusinessRole ? '업체명' : '이름'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: _isBusinessRole ? '업체명을 입력해 주세요' : '이름을 입력해 주세요',
                ),
              ),
              const SizedBox(height: 20),

              // ──────── 4-1. 대표자 성명 (협력업체/주관사만) ────────
              if (_isBusinessRole) ...[
                const _SectionLabel(text: '대표자 성명'),
                const SizedBox(height: 8),
                TextField(
                  controller: _representativeNameController,
                  decoration: const InputDecoration(hintText: '대표자 성명을 입력해 주세요'),
                ),
                const SizedBox(height: 20),
              ],

              // ──────── 5. 전화번호 (010-0000-0000) ────────
              const _SectionLabel(text: '전화번호'),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [_PhoneNumberFormatter()],
                decoration: const InputDecoration(hintText: '010-0000-0000'),
              ),
              const SizedBox(height: 20),

              // ──────── 6. 사업자등록번호 (협력업체/주관사만) ────────
              if (_isBusinessRole) ...[
                const _SectionLabel(text: '사업자등록번호'),
                const SizedBox(height: 8),
                TextField(
                  controller: _businessNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_BusinessNumberFormatter()],
                  decoration: const InputDecoration(hintText: '000-00-00000'),
                ),
                const SizedBox(height: 20),

                // ──────── 6-1. 사업장 주소 (협력업체/주관사만) ────────
                const _SectionLabel(text: '사업장 주소'),
                const SizedBox(height: 8),
                TextField(
                  controller: _businessAddressController,
                  decoration: const InputDecoration(hintText: '사업장 주소를 입력해 주세요'),
                ),
                const SizedBox(height: 20),

                // ──────── 7. 사업자등록증 첨부 (협력업체/주관사만) ────────
                const _SectionLabel(text: '사업자등록증 첨부'),
                const SizedBox(height: 8),
                _buildImageUploadArea(),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 12),

              // 회원가입 버튼
              AppButton(
                text: '회원가입',
                onPressed: _handleRegister,
                isLoading: _isLoading,
              ),

              // 협력업체/주관사일 때 승인 안내 문구
              if (_isBusinessRole)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    '* 협력업체/주관사는 관리자 승인 후 로그인할 수 있습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
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

  // 사업자등록증 이미지 업로드 영역
  Widget _buildImageUploadArea() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 업로드 기능은 추후 추가됩니다')),
        );
      },
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 36, color: AppColors.textHint),
            SizedBox(height: 8),
            Text(
              '사업자등록증 이미지 첨부',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
            SizedBox(height: 4),
            Text(
              '(jpg, png, pdf)',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 전화번호 자동 포맷터 (010-0000-0000)
// 숫자만 입력받고 하이픈을 자동 삽입
// ============================================
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 숫자만 남기기
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 최대 11자리
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;

    // 하이픈 삽입 (010-0000-0000 형식)
    String formatted;
    if (limited.length <= 3) {
      formatted = limited;
    } else if (limited.length <= 7) {
      formatted = '${limited.substring(0, 3)}-${limited.substring(3)}';
    } else {
      formatted = '${limited.substring(0, 3)}-${limited.substring(3, 7)}-${limited.substring(7)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ============================================
// 사업자등록번호 자동 포맷터 (000-00-00000)
// 숫자만 입력받고 하이픈을 자동 삽입
// ============================================
class _BusinessNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 숫자만 남기기
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 최대 10자리
    final limited = digits.length > 10 ? digits.substring(0, 10) : digits;

    // 하이픈 삽입 (000-00-00000 형식)
    String formatted;
    if (limited.length <= 3) {
      formatted = limited;
    } else if (limited.length <= 5) {
      formatted = '${limited.substring(0, 3)}-${limited.substring(3)}';
    } else {
      formatted = '${limited.substring(0, 3)}-${limited.substring(3, 5)}-${limited.substring(5)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// 섹션 라벨 ("이메일", "비밀번호" 같은 제목)
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
