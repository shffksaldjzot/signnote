import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../services/user_service.dart';
import '../../services/event_service.dart';
import '../../services/api_service.dart';
import '../../widgets/layout/app_header.dart';

// ============================================
// 개인정보 수정 화면 (Profile Edit Screen)
//
// 역할별 필드:
//   - 고객: 이름, 전화번호, (동/호수 — 행사 참여 중일 때만), 비밀번호
//   - 업체/주관사: 업체명, 대표자 성명, 전화번호, 사업자등록번호,
//                  사업장 주소, 비밀번호
//
// 비밀번호는 변경하고 싶을 때만 입력 (선택)
// ============================================

class ProfileEditScreen extends StatefulWidget {
  final String role;

  const ProfileEditScreen({
    super.key,
    required this.role,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final UserService _userService = UserService();
  final EventService _eventService = EventService();

  // 공통 컨트롤러
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // 업체/주관사 전용 컨트롤러
  final _representativeNameController = TextEditingController();
  final _businessNumberController = TextEditingController();
  final _businessAddressController = TextEditingController();

  // 고객 전용 (동/호수)
  final _dongController = TextEditingController();
  final _hoController = TextEditingController();

  // 비밀번호 변경 (선택사항)
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _eventId; // 고객이 참여 중인 행사 ID (동/호수 저장용)

  // 고객 전용: 평형 타입 드롭다운
  String? _selectedHousingType;
  List<String> _availableHousingTypes = [];

  // 협력업체 또는 주관사인지 확인
  bool get _isBusinessRole =>
      widget.role == 'VENDOR' || widget.role == 'ORGANIZER';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _representativeNameController.dispose();
    _businessNumberController.dispose();
    _businessAddressController.dispose();
    _dongController.dispose();
    _hoController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 서버에서 내 프로필 정보 가져오기
  Future<void> _loadProfile() async {
    final result = await _userService.getMyProfile();

    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'];
      // 고객: 행사의 가용 타입 목록 미리 로드
      final events = user['participatedEvents'] as List? ?? [];
      if (widget.role == 'CUSTOMER' && events.isNotEmpty) {
        final evtId = events.first['eventId']?.toString();
        if (evtId != null) {
          _loadAvailableHousingTypes(evtId);
        }
      }
      setState(() {
        _nameController.text = user['name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _representativeNameController.text = user['representativeName'] ?? '';
        _businessNumberController.text = user['businessNumber'] ?? '';
        _businessAddressController.text = user['businessAddress'] ?? '';

        // 고객인 경우 참여 행사의 동/호수/타입 설정
        final events = user['participatedEvents'] as List? ?? [];
        if (events.isNotEmpty) {
          final firstEvent = events.first;
          _dongController.text = firstEvent['dong'] ?? '';
          _hoController.text = firstEvent['ho'] ?? '';
          _eventId = firstEvent['eventId'];
          _selectedHousingType = firstEvent['housingType']?.toString();
        }

        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? '프로필 정보를 불러올 수 없습니다')),
        );
      }
    }
  }

  // 행사의 가용 평형 타입 목록 가져오기
  Future<void> _loadAvailableHousingTypes(String eventId) async {
    final result = await _eventService.getEventDetail(eventId);
    if (!mounted) return;
    if (result['success'] == true) {
      final event = result['event'] as Map<String, dynamic>? ?? {};
      final types = event['housingTypes'] as List?;
      if (types != null) {
        setState(() {
          _availableHousingTypes = List<String>.from(types);
        });
      }
    }
  }

  // 저장 버튼 클릭
  Future<void> _handleSave() async {
    // 입력값 검증
    if (_nameController.text.trim().isEmpty) {
      _showError(_isBusinessRole ? '업체명을 입력해 주세요' : '이름을 입력해 주세요');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('전화번호를 입력해 주세요');
      return;
    }

    // 비밀번호 변경 검증 (입력한 경우만)
    final hasNewPassword = _newPasswordController.text.isNotEmpty;
    if (hasNewPassword) {
      if (_currentPasswordController.text.isEmpty) {
        _showError('현재 비밀번호를 입력해 주세요');
        return;
      }
      if (_newPasswordController.text.length < 6) {
        _showError('새 비밀번호는 6자 이상이어야 합니다');
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showError('새 비밀번호가 일치하지 않습니다');
        return;
      }
    }

    setState(() => _isSaving = true);

    // 프로필 데이터 구성
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    // 업체/주관사 추가 필드
    if (_isBusinessRole) {
      data['representativeName'] = _representativeNameController.text.trim();
      data['businessNumber'] = _businessNumberController.text.trim();
      data['businessAddress'] = _businessAddressController.text.trim();
    }

    // 비밀번호 변경 (입력한 경우만)
    if (hasNewPassword) {
      data['currentPassword'] = _currentPasswordController.text;
      data['newPassword'] = _newPasswordController.text;
    }

    // 프로필 업데이트 API 호출
    final result = await _userService.updateProfile(data);

    if (!mounted) return;

    if (result['success'] == true) {
      // SharedPreferences 업데이트
      final user = result['user'];
      if (user != null) {
        await ApiService().saveUserInfo(Map<String, dynamic>.from(user));
      }

      // 고객이 동/호수/타입 변경한 경우 별도로 저장
      if (widget.role == 'CUSTOMER' && _eventId != null) {
        await _eventService.updateParticipantInfo(
          _eventId!,
          dong: _dongController.text.trim(),
          ho: _hoController.text.trim(),
          housingType: _selectedHousingType,
        );
      }

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 수정되었습니다')),
      );

      // 비밀번호 입력 필드 초기화
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      Navigator.of(context).pop(true); // true 반환하여 마이페이지 새로고침
    } else {
      setState(() => _isSaving = false);
      _showError(result['error'] ?? '프로필 수정에 실패했습니다');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppHeader(title: '개인정보 수정'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ──── 이름/업체명 ────
                  _SectionLabel(text: _isBusinessRole ? '업체명' : '이름'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: _isBusinessRole ? '업체명' : '이름',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ──── 대표자 성명 (업체/주관사만) ────
                  if (_isBusinessRole) ...[
                    const _SectionLabel(text: '대표자 성명'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _representativeNameController,
                      decoration: const InputDecoration(hintText: '대표자 성명'),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ──── 전화번호 ────
                  const _SectionLabel(text: '전화번호'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_PhoneNumberFormatter()],
                    decoration: const InputDecoration(hintText: '010-0000-0000'),
                  ),
                  const SizedBox(height: 20),

                  // ──── 사업자등록번호 (업체/주관사만) ────
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

                    // ──── 사업장 주소 (업체/주관사만) ────
                    const _SectionLabel(text: '사업장 주소'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _businessAddressController,
                      decoration: const InputDecoration(hintText: '사업장 주소'),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ──── 동/호수 (고객만, 행사 참여 중일 때) ────
                  if (widget.role == 'CUSTOMER' && _eventId != null) ...[
                    const _SectionLabel(text: '동/호수'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dongController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '',
                              suffixText: '동',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _hoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '',
                              suffixText: '호',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ──── 평형 타입 (드롭다운) ────
                    const _SectionLabel(text: '평형 타입'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _availableHousingTypes.contains(_selectedHousingType)
                              ? _selectedHousingType
                              : null,
                          hint: const Text('타입 선택', style: TextStyle(color: AppColors.textHint)),
                          isExpanded: true,
                          items: [
                            // 첫 번째 줄: 미지정 상태
                            const DropdownMenuItem<String>(value: null, child: Text('미지정', style: TextStyle(color: AppColors.textHint))),
                            ..._availableHousingTypes.map((type) {
                              return DropdownMenuItem<String>(value: type, child: Text(type));
                            }),
                          ],
                          onChanged: (v) => setState(() => _selectedHousingType = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ──── 비밀번호 변경 (선택) ────
                  const Divider(),
                  const SizedBox(height: 12),
                  const _SectionLabel(text: '비밀번호 변경'),
                  const SizedBox(height: 4),
                  const Text(
                    '변경하려면 아래 필드를 입력해 주세요. 비워두면 변경하지 않습니다.',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: '현재 비밀번호',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: '새 비밀번호 (6자 이상)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: '새 비밀번호 확인',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ──── 저장 버튼 ────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('저장'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// 섹션 라벨
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

// 전화번호 자동 포맷터 (010-0000-0000)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;

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

// 사업자등록번호 자동 포맷터 (000-00-00000)
class _BusinessNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 10 ? digits.substring(0, 10) : digits;

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
