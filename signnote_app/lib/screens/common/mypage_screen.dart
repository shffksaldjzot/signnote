import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'profile_edit_screen.dart';

// ============================================
// 마이페이지 화면
//
// 사용자 정보(이름, 이메일, 역할)를 보여주고
// 로그아웃, 알림 확인 등 공통 기능을 제공.
// 고객/업체/주관사 모두 공용으로 사용.
// ============================================

class MypageScreen extends StatefulWidget {
  final String role; // 현재 사용자 역할
  final bool embedded; // true이면 body만 반환

  const MypageScreen({
    super.key,
    required this.role,
    this.embedded = false,
  });

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  String _userName = '';
  String _userEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 저장된 사용자 정보 불러오기
  Future<void> _loadUserInfo() async {
    final userInfo = await _apiService.getUserInfo();
    if (!mounted) return;
    setState(() {
      _userName = userInfo?['name'] ?? '사용자';
      _userEmail = userInfo?['email'] ?? '';
      _isLoading = false;
    });
  }

  // 역할 한글 변환
  String get _roleLabel {
    switch (widget.role) {
      case 'VENDOR':
        return '협력업체';
      case 'ORGANIZER':
        return '주관사';
      case 'ADMIN':
        return '관리자';
      default:
        return '고객';
    }
  }

  // 로그아웃 확인 다이얼로그
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '로그아웃',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: const Text('로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.priceRed),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  // 로그아웃 실행
  Future<void> _performLogout() async {
    await _authService.logout();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  // 마이페이지 본문 위젯
  Widget _buildMypageBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 프로필 카드
                _buildProfileCard(),
                const SizedBox(height: 24),
                // 메뉴 항목들
                _buildMenuItem(
                  icon: null,
                  customIcon: Image.asset('assets/icons/vendor/write.png', width: 22, height: 22),
                  title: '개인정보 수정',
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ProfileEditScreen(role: widget.role),
                      ),
                    );
                    // 수정 완료 시 마이페이지 새로고침
                    if (result == true) _loadUserInfo();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: '알림',
                  onTap: () => context.push(AppRoutes.notifications),
                ),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: '이용약관',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이용약관은 준비 중입니다')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.lock_outlined,
                  title: '개인정보처리방침',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('개인정보처리방침은 준비 중입니다')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: '앱 버전',
                  trailing: const Text(
                    'v1.0.0',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // 로그아웃 버튼
                _buildMenuItem(
                  icon: Icons.logout,
                  title: '로그아웃',
                  titleColor: AppColors.priceRed,
                  onTap: _showLogoutDialog,
                ),
              ],
            );
  }

  @override
  Widget build(BuildContext context) {
    // 임베디드 모드: body만 반환 (EventDetailScreen의 IndexedStack에서 사용)
    if (widget.embedded) {
      return _buildMypageBody();
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppHeader(title: '마이페이지'),
      bottomNavigationBar: _buildBottomBar(),
      body: _buildMypageBody(),
    );
  }

  // 역할별 하단 탭바 생성
  Widget? _buildBottomBar() {
    switch (widget.role) {
      case 'CUSTOMER':
        return AppTabBar.customer(
          currentIndex: 3, // 마이페이지 = 4번째 탭
          onTap: _onCustomerTabChanged,
        );
      case 'VENDOR':
        return AppTabBar.vendor(
          currentIndex: 1, // 마이페이지 = 2번째 탭
          onTap: _onVendorTabChanged,
        );
      case 'ORGANIZER':
        return AppTabBar.organizer(
          currentIndex: 1, // 마이페이지 = 2번째 탭
          onTap: _onOrganizerTabChanged,
        );
      default:
        return null;
    }
  }

  // 고객 탭 이동
  void _onCustomerTabChanged(int index) {
    if (index == 3) return; // 마이페이지 현재 화면
    Navigator.pop(context); // 현재 화면 닫고 이전 화면으로
  }

  // 업체 탭 이동
  void _onVendorTabChanged(int index) {
    if (index == 1) return; // 마이페이지 현재 화면
    Navigator.pop(context);
  }

  // 주관사 탭 이동
  void _onOrganizerTabChanged(int index) {
    if (index == 1) return; // 마이페이지 현재 화면
    Navigator.pop(context);
  }

  // 프로필 카드 (이름, 이메일, 역할 뱃지)
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 아바타
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Text(
              _userName.isNotEmpty ? _userName[0] : '?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 이름 + 이메일 + 역할 뱃지
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _roleLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_userEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 메뉴 항목 (아이콘 + 제목 + 화살표)
  Widget _buildMenuItem({
    IconData? icon,
    Widget? customIcon,
    required String title,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: customIcon ?? Icon(icon, color: titleColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textHint)
              : null),
      onTap: onTap,
    );
  }
}
