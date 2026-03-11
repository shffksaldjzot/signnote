import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/event/event_card.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'event_detail_screen.dart';

// ============================================
// 업체(협력업체) 홈 화면 (2차 디자인)
//
// 디자인 참고: 2.업체용-행사 목록.jpg
// - 상단: Signnote 로고 + "협력업체" 뱃지
// - "행사 목록 >" 제목
// - 행사 카드 그리드 (2열), + 카드는 맨 뒤
// - + 카드 클릭 → 참여 코드 팝업 (2.업체용-행사 목록-추가.jpg)
// - 하단: 2탭 네비게이션 (홈/마이페이지)
// - 신규 업체(행사 없음) → 첫 페이지처럼 코드 입력 안내
// ============================================

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  final int _currentTabIndex = 0;

  // API에서 가져온 행사 목록
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;

  // 행사별 읽지 않은 알림 수 (알림 배지용)
  Map<String, int> _unreadCounts = {};

  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadUnreadCounts();
  }

  // 행사별 읽지 않은 알림 수 가져오기
  Future<void> _loadUnreadCounts() async {
    final result = await _notificationService.getUnreadCountByEvents();
    if (!mounted) return;
    if (result['success'] == true) {
      final Map<String, dynamic> counts = result['counts'] ?? {};
      setState(() {
        _unreadCounts = counts.map((k, v) => MapEntry(k, (v as num).toInt()));
      });
    }
  }

  // 서버에서 행사 목록 가져오기
  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _eventService.getEvents();

    if (!mounted) return;

    if (result['success'] == true) {
      final List events = result['events'] ?? [];
      setState(() {
        _events = events.map<Map<String, dynamic>>((e) {
          return {
            'id': e['id']?.toString() ?? '',
            'title': e['title'] ?? '행사명 없음',
            'coverImageUrl': e['coverImage'],
            'entryCode': e['entryCode'],
            'startDate': e['startDate'] != null
                ? DateTime.tryParse(e['startDate'].toString())
                : null,
            'endDate': e['endDate'] != null
                ? DateTime.tryParse(e['endDate'].toString())
                : null,
          };
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? '행사 목록을 불러올 수 없습니다';
        _isLoading = false;
      });
    }
  }

  // 참여 코드 입력 팝업 (디자인: 2.업체용-행사 목록-추가.jpg)
  void _showEntryCodePopup() {
    final codeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 32, bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 텍스트
            const Text(
              '안녕하세요.\n사인노트 사용을 위해\n행사 참여 코드를 입력해 주세요.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // 6자리 코드 입력
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 12,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                  color: AppColors.textHint.withValues(alpha: 0.3),
                ),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // "입장하기" 검정 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final code = codeController.text;
                  if (code.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('6자리 코드를 입력해 주세요')),
                    );
                    return;
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  // 참여 코드로 행사 입장 API 호출
                  final result = await _authService.enterEvent(code);
                  if (!mounted) return;
                  if (result['success'] == true) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('행사에 참여했습니다!')),
                    );
                    _loadEvents();
                  } else {
                    messenger.showSnackBar(
                      SnackBar(content: Text(result['error'] ?? '입장에 실패했습니다')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vendor, // 검정
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('입장하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 탭 클릭 시 화면 이동 (2탭: 홈/마이페이지)
  void _onTabChanged(int index) {
    if (index == _currentTabIndex) return;
    switch (index) {
      case 0: // 홈 — 현재 화면
        break;
      case 1: // 마이페이지
        context.push(AppRoutes.mypage, extra: 'VENDOR');
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // 로고 + "협력업체" 뱃지
                _buildLogo(),
                const SizedBox(height: 24),
                // "행사 목록 >" 제목
                const Row(
                  children: [
                    Text(
                      '행사 목록',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: AppColors.textPrimary, size: 22),
                  ],
                ),
                const SizedBox(height: 16),
                // 행사 카드 그리드
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
        // 하단 탭바 (업체용 2탭)
        bottomNavigationBar: AppTabBar.vendor(
          currentIndex: _currentTabIndex,
          onTap: _onTabChanged,
        ),
      ),
    );
  }

  // 본문 영역
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.vendor));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadEvents, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    // 신규 업체(행사 없음) → 첫 페이지처럼 코드 입력 안내 (1.업체용-첫 페이지.jpg)
    if (_events.isEmpty) {
      return _buildFirstTimeView();
    }

    // 행사가 있으면 그리드 (+ 카드는 맨 뒤)
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: _events.length + 1,
      itemBuilder: (context, index) {
        // 맨 앞에 + 추가 카드
        if (index == 0) {
          return AddEventCard(onTap: _showEntryCodePopup);
        }

        final event = _events[index - 1];
        final eventId = event['id']?.toString() ?? '';
        return EventCard(
          title: event['title'],
          coverImageUrl: event['coverImageUrl'],
          startDate: event['startDate'],
          endDate: event['endDate'],
          notificationCount: _unreadCounts[eventId] ?? 0,  // 알림 배지 숫자
          onTap: () {
            // 행사 상세 (3탭) 화면으로 이동
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VendorEventDetailScreen(
                  eventId: event['id'],
                  eventTitle: event['title'],
                ),
              ),
            ).then((_) => _loadUnreadCounts());  // 돌아오면 알림 수 갱신
          },
          onMoreTap: () => _showEventMenu(event),
        );
      },
    );
  }

  // 신규 업체용 첫 화면 (행사 없을 때)
  Widget _buildFirstTimeView() {
    final codeController = TextEditingController();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            '안녕하세요.\n사인노트 사용을 위해\n행사 참여 코드를 입력해 주세요.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          // 6자리 코드 입력
          TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 12,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 12,
                color: AppColors.textHint.withValues(alpha: 0.3),
              ),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // "입장하기" 검정 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final code = codeController.text;
                if (code.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('6자리 코드를 입력해 주세요')),
                  );
                  return;
                }
                final result = await _authService.enterEvent(code);
                if (!mounted) return;
                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('행사에 참여했습니다!')),
                  );
                  _loadEvents();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['error'] ?? '입장에 실패했습니다')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vendor,
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

  // 행사 카드 3점 메뉴 (참가 취소)
  void _showEventMenu(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('행사 참가 취소', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmCancelParticipation(event);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 참가 취소 확인 팝업
  void _confirmCancelParticipation(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('참가 취소', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          '\'${event['title']}\' 행사 참가를 취소하시겠습니까?\n\n취소하면 이 행사의 모든 데이터에 접근할 수 없습니다.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('아니오')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordConfirmDialog(event);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
  }

  // 비밀번호 확인 후 참가 취소
  void _showPasswordConfirmDialog(Map<String, dynamic> event) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('비밀번호 확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('참가 취소를 위해 본인 계정 비밀번호를 입력해 주세요.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '비밀번호',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('비밀번호를 입력해 주세요')),
                );
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);

              final verifyResult = await _authService.verifyPassword(password);
              if (!mounted) return;
              if (verifyResult['success'] != true) {
                messenger.showSnackBar(
                  SnackBar(content: Text(verifyResult['error'] ?? '비밀번호가 올바르지 않습니다')),
                );
                return;
              }

              final leaveResult = await _eventService.leaveEvent(event['id']);
              if (!mounted) return;
              if (leaveResult['success'] == true) {
                messenger.showSnackBar(const SnackBar(content: Text('행사 참가가 취소되었습니다')));
                _loadEvents();
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text(leaveResult['error'] ?? '참가 취소에 실패했습니다')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 로고 + "협력업체" 뱃지
  Widget _buildLogo() {
    return Row(
      children: [
        Image.asset('assets/images/logo.png', height: 28, fit: BoxFit.contain),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.vendor, // 검정
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '협력업체',
            style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
