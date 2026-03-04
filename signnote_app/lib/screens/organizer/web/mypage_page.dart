import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../services/api_service.dart';
import '../../../services/user_service.dart';

// ============================================
// 웹 대시보드용 마이페이지 (MyPage)
//
// 구조:
// ┌──────────────────────────────────────┐
// | 마이페이지                           |
// ├──────────────────────────────────────┤
// | [프로필 카드]                        |
// |  이름 / 이메일 / 역할                |
// ├──────────────────────────────────────┤
// | [비밀번호 변경]                      |
// |  현재 비밀번호 / 새 비밀번호 / 확인   |
// |  [변경하기] 버튼                     |
// └──────────────────────────────────────┘
// ============================================

class MypagePage extends StatefulWidget {
  const MypagePage({super.key});

  @override
  State<MypagePage> createState() => _MypagePageState();
}

class _MypagePageState extends State<MypagePage> {
  final ApiService _apiService = ApiService();
  final UserService _userService = UserService();

  // 사용자 정보
  String _userName = '';
  String _userEmail = '';
  String _userRole = '';
  bool _isLoading = true;

  // 비밀번호 변경 폼 컨트롤러
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _isChanging = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    final userInfo = await _apiService.getUserInfo();
    if (!mounted) return;
    setState(() {
      _userName = userInfo?['name'] ?? '사용자';
      _userEmail = userInfo?['email'] ?? '';
      _userRole = userInfo?['role'] ?? '';
      _isLoading = false;
    });
  }

  // 역할 한글 변환
  String get _roleLabel {
    switch (_userRole) {
      case 'ADMIN':
        return '관리자';
      case 'ORGANIZER':
        return '주관사';
      case 'VENDOR':
        return '협력업체';
      default:
        return '고객';
    }
  }

  // 역할별 뱃지 색상
  Color get _roleColor {
    switch (_userRole) {
      case 'ADMIN':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  // 비밀번호 변경 실행
  Future<void> _changePassword() async {
    // 입력값 검증
    if (_currentPwController.text.isEmpty ||
        _newPwController.text.isEmpty ||
        _confirmPwController.text.isEmpty) {
      _showSnackBar('모든 필드를 입력해주세요');
      return;
    }
    if (_newPwController.text != _confirmPwController.text) {
      _showSnackBar('새 비밀번호가 일치하지 않습니다');
      return;
    }
    if (_newPwController.text.length < 6) {
      _showSnackBar('비밀번호는 6자 이상이어야 합니다');
      return;
    }

    setState(() => _isChanging = true);

    final result = await _userService.changePassword(
      currentPassword: _currentPwController.text,
      newPassword: _newPwController.text,
    );

    setState(() => _isChanging = false);

    if (!mounted) return;

    if (result['success'] == true) {
      _showSnackBar('비밀번호가 변경되었습니다');
      // 입력 필드 초기화
      _currentPwController.clear();
      _newPwController.clear();
      _confirmPwController.clear();
    } else {
      _showSnackBar(result['error'] ?? '비밀번호 변경에 실패했습니다');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 페이지 제목 ──
                const Text(
                  '마이페이지',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // ── 프로필 카드 ──
                AppCard(
                  child: Row(
                    children: [
                      // 아바타 (이름 첫 글자)
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: _roleColor,
                        child: Text(
                          _userName.isNotEmpty ? _userName[0] : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 이름 + 이메일 + 역할
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _roleColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _roleLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _roleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _userEmail,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── 비밀번호 변경 섹션 ──
                const Text(
                  '비밀번호 변경',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                AppCard(
                  child: SizedBox(
                    width: 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 현재 비밀번호
                        TextField(
                          controller: _currentPwController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '현재 비밀번호',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 새 비밀번호
                        TextField(
                          controller: _newPwController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '새 비밀번호',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_reset),
                            helperText: '6자 이상 입력해주세요',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 새 비밀번호 확인
                        TextField(
                          controller: _confirmPwController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '새 비밀번호 확인',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_reset),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 변경 버튼
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isChanging ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isChanging
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    '비밀번호 변경',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
