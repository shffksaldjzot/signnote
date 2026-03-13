import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/common/skeleton_loading.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_transitions.dart';
import 'event_detail_screen.dart';
import 'cart_screen.dart';
import 'contract_screen.dart';

// ============================================
// 고객 홈 화면 (1계정 1행사 구조)
//
// 디자인 참고: 1.고객용-첫 페이지.jpg / 2.고객용-평형 선택.jpg
// - 이미 행사에 참여 중이면 → 바로 행사 상세로 직행
// - 아직 행사 없으면 → 6자리 코드 입력 화면 표시
// - 코드 입력 성공 → 평형 선택 팝업 → 행사 상세로 이동
// ============================================

class CustomerHomeScreen extends StatefulWidget {
  final String role;

  const CustomerHomeScreen({
    super.key,
    this.role = AppConstants.roleCustomer,
  });

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final int _currentTabIndex = 0;

  // 참여 중인 행사 정보
  Map<String, dynamic>? _currentEvent;
  bool _isLoading = true;
  String? _error;

  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();

  // 코드 입력 컨트롤러 (6칸 각각)
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes =
      List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _checkExistingEvent();
  }

  @override
  void dispose() {
    for (final c in _codeControllers) { c.dispose(); }
    for (final f in _codeFocusNodes) { f.dispose(); }
    super.dispose();
  }

  // 이미 참여 중인 행사가 있는지 확인
  Future<void> _checkExistingEvent() async {
    setState(() { _isLoading = true; _error = null; });

    final result = await _eventService.getEvents();

    if (!mounted) return;

    if (result['success'] == true) {
      final List events = result['events'] ?? [];
      if (events.isNotEmpty) {
        // 1계정 1행사: 첫 번째 행사로 바로 직행
        final event = events.first;
        setState(() {
          _currentEvent = {
            'id': event['id']?.toString() ?? '',
            'title': event['title'] ?? '행사명 없음',
          };
          _isLoading = false;
        });
        // 바로 행사 상세로 이동
        _goToEventDetail();
        return;
      }
    }

    setState(() { _isLoading = false; });
  }

  // 행사 상세 화면으로 이동
  void _goToEventDetail() {
    if (_currentEvent == null) return;

    // 페이드+슬라이드 전환 애니메이션 적용
    Navigator.of(context).pushReplacement(
      fadeSlideRoute(
        EventDetailScreen(
          eventId: _currentEvent!['id'],
          eventTitle: _currentEvent!['title'],
        ),
      ),
    );
  }

  // 6자리 코드 얻기
  String get _entryCode {
    return _codeControllers.map((c) => c.text).join();
  }

  // 입장하기 버튼 클릭
  Future<void> _handleEnter() async {
    final code = _entryCode;
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('6자리 코드를 모두 입력해 주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.enterEvent(code);

    if (!mounted) return;

    if (result['success'] == true) {
      final event = result['event'] as Map<String, dynamic>;
      final eventId = event['eventId']?.toString() ?? '';
      final eventTitle = event['title']?.toString() ?? '행사';
      final housingTypes = List<String>.from(event['housingTypes'] ?? []);

      setState(() {
        _currentEvent = {'id': eventId, 'title': eventTitle};
        _isLoading = false;
      });

      // 평형 선택 팝업 표시
      if (mounted) {
        _showHousingInfoDialog(eventId, eventTitle, housingTypes);
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? '입장에 실패했습니다')),
        );
      }
    }
  }

  // 평형 선택 팝업 (C-2)
  void _showHousingInfoDialog(String eventId, String eventTitle, List<String> housingTypes) {
    final dongController = TextEditingController();
    final hoController = TextEditingController();
    String? selectedType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 행사명
              Text(
                eventTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              // 동호수 입력
              const Text('동호수를 입력해 주세요.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  // 동 입력
                  Expanded(
                    child: TextField(
                      controller: dongController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '',
                        suffixText: '동',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 호 입력
                  Expanded(
                    child: TextField(
                      controller: hoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '',
                        suffixText: '호',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 타입 선택
              const Text('타입을 선택해 주세요.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ...housingTypes.map((type) => RadioListTile<String>(
                title: Text('$type 타입'),
                value: type,
                groupValue: selectedType,
                onChanged: (v) => setSheetState(() => selectedType = v),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )),
              const SizedBox(height: 20),
              // 완료 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (dongController.text.isEmpty || hoController.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('동호수를 입력해 주세요')),
                      );
                      return;
                    }
                    if (selectedType == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('타입을 선택해 주세요')),
                      );
                      return;
                    }

                    // async 호출 전에 navigator 미리 캡처
                    final navigator = Navigator.of(context);
                    final ctxNavigator = Navigator.of(ctx);

                    // 서버에 평형 정보 저장
                    await _eventService.updateParticipantInfo(
                      eventId,
                      dong: dongController.text,
                      ho: hoController.text,
                      housingType: selectedType,
                    );

                    if (!context.mounted) return;
                    ctxNavigator.pop();

                    // 행사 상세로 이동 (페이드+슬라이드 전환 애니메이션)
                    navigator.pushReplacement(
                      fadeSlideRoute(
                        EventDetailScreen(
                          eventId: eventId,
                          eventTitle: eventTitle,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('완료'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 탭 클릭 시 화면 이동
  void _onTabChanged(int index) {
    if (index == _currentTabIndex) return;

    switch (index) {
      case 0: break; // 홈 — 현재
      case 1: // 장바구니
        if (_currentEvent != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CartScreen(
                eventId: _currentEvent!['id'],
                eventTitle: _currentEvent!['title'],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('행사에 참여한 후 이용해 주세요')),
          );
        }
        break;
      case 2: // 계약함
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CustomerContractScreen()),
        );
        break;
      case 3: // 마이페이지
        context.push(AppRoutes.mypage, extra: widget.role);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: _isLoading
              ? const SkeletonList(itemCount: 3) // 로딩 중 스켈레톤 표시
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.priceRed)))
                  : _buildEntryCodePage(),
        ),
        bottomNavigationBar: AppTabBar.customer(
          currentIndex: _currentTabIndex,
          onTap: _onTabChanged,
        ),
      ),
    );
  }

  // 코드 입력 페이지 (디자인: 1.고객용-첫 페이지.jpg)
  Widget _buildEntryCodePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Signnote 로고
          Image.asset('assets/images/logo.png', height: 28, fit: BoxFit.contain),
          const SizedBox(height: 32),
          // 안내 문구
          const Text(
            '안녕하세요.\n사인노트 사용을 위해\n행사 참여 코드를 입력해 주세요.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 48),
          // 6자리 코드 입력 (개별 칸)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => _buildCodeBox(i)),
          ),
          const SizedBox(height: 32),
          // 입장하기 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleEnter,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('입장하기'),
            ),
          ),
        ],
      ),
    );
  }

  // 코드 입력 칸 1개
  Widget _buildCodeBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _codeControllers[index],
        focusNode: _codeFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            // 다음 칸으로 포커스 이동
            _codeFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            // 빈 칸이면 이전 칸으로
            _codeFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
