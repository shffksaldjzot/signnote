import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/common/app_button.dart';

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

  // 입장하기 버튼 눌렀을 때
  Future<void> _handleEnter() async {
    if (_entryCode.length < AppConstants.entryCodeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참여 코드 6자리를 모두 입력해 주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: 실제 API 연동
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('입력한 코드: $_entryCode (API 연동 예정)')),
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

              // 로고 + 역할 뱃지
              Row(
                children: [
                  // 로고 아이콘
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Icon(Icons.edit_document, color: AppColors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // "signnote" 텍스트
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'sign',
                          style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: 'note',
                          style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
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
              const SizedBox(height: 60),
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
