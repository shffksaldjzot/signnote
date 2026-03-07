import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../widgets/event/event_card.dart';
import '../../services/event_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'event_form_screen.dart';
import 'event_manage_screen.dart';

// ============================================
// 주관사 홈 화면 (2차 디자인)
//
// 디자인 참고: 1.주관사용-처음.jpg / 3.주관사용-행사 목록.jpg
// - 상단: Signnote 로고 + 주황색 "주관사" 뱃지
// - "행사 목록 >" 제목
// - 행사 카드 그리드 (2열) + 맨 앞 + 카드
// - 하단: 홈 / 마이페이지 (2탭, 주황색 아이콘)
// ============================================

class OrganizerHomeScreen extends StatefulWidget {
  const OrganizerHomeScreen({super.key});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  // API에서 가져온 행사 목록
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;
  String _currentRole = 'ORGANIZER';
  int _currentTabIndex = 0; // 하단 탭 인덱스 (0=홈, 1=마이페이지)

  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  // 행사별 안 읽은 알림 개수 { eventId: count }
  Map<String, int> _unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadEvents();
    _loadUnreadCounts();
  }

  // 행사별 안 읽은 알림 개수 가져오기
  Future<void> _loadUnreadCounts() async {
    final result = await _notificationService.getUnreadCountByEvents();
    if (!mounted) return;
    if (result['success'] == true) {
      final counts = result['counts'] as Map<String, dynamic>? ?? {};
      setState(() {
        _unreadCounts = counts.map((k, v) => MapEntry(k, (v as num).toInt()));
      });
    }
  }

  // 저장된 사용자 역할 가져오기
  Future<void> _loadUserRole() async {
    final userInfo = await ApiService().getUserInfo();
    if (!mounted) return;
    setState(() {
      _currentRole = userInfo?['role'] ?? 'ORGANIZER';
    });
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
            'organizerName': e['organizer']?['name'],
            'coverImageUrl': e['coverImage'],
            'startDate': e['startDate'] != null
                ? DateTime.tryParse(e['startDate'].toString())
                : null,
            'endDate': e['endDate'] != null
                ? DateTime.tryParse(e['endDate'].toString())
                : null,
            'entryCode': e['entryCode']?.toString(),
            'vendorEntryCode': e['vendorEntryCode']?.toString(),
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

  // 하단 탭 변경
  void _onTabChanged(int index) {
    if (index == 1) {
      // 마이페이지
      context.push(AppRoutes.mypage, extra: _currentRole);
      return;
    }
    setState(() => _currentTabIndex = index);
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
                // 로고 + "주관사" 주황 뱃지
                _buildLogo(),
                const SizedBox(height: 24),
                // "행사 목록 >" 제목
                Row(
                  children: [
                    const Text(
                      '행사 목록',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 행사 카드 그리드
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
        // 하단: 홈 / 마이페이지 (2탭, 주황 아이콘)
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _onTabChanged,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.organizer,     // 주황색 (활성)
          unselectedItemColor: AppColors.textSecondary, // 회색 (비활성)
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset('assets/icons/organizer/home_active.png', width: 24, height: 24,
                color: _currentTabIndex == 0 ? AppColors.organizer : AppColors.textSecondary),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '마이페이지',
            ),
          ],
        ),
      ),
    );
  }

  // 본문 영역: 로딩 / 에러 / 행사 목록 분기
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.organizer));
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

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: _events.length + 1,
      itemBuilder: (context, index) {
        // 맨 앞 + 추가 카드
        if (index == 0) {
          return AddEventCard(
            onTap: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const OrganizerEventFormScreen(),
                ),
              );
              if (result == true) _loadEvents();
            },
          );
        }

        final event = _events[index - 1];
        final eventId = event['id'] as String;
        return EventCard(
          title: event['title'],
          organizerName: event['organizerName'],
          coverImageUrl: event['coverImageUrl'],
          startDate: event['startDate'],
          endDate: event['endDate'],
          badgeColor: AppColors.organizer, // 주황색 D-day 뱃지
          notificationCount: _unreadCounts[eventId] ?? 0,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrganizerEventManageScreen(
                  eventId: eventId,
                  eventTitle: event['title'],
                  entryCode: event['entryCode'],
                  vendorEntryCode: event['vendorEntryCode'],
                ),
              ),
            ).then((_) => _loadUnreadCounts());
          },
          onMoreTap: () => _showEventMenu(event),
        );
      },
    );
  }

  // 행사 카드 3점 메뉴 (수정/삭제) — 디자인: 3.주관사용-행사 목록.jpg
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
              leading: const Icon(Icons.edit_outlined),
              title: const Text('수정'),
              onTap: () {
                Navigator.pop(context);
                _editEvent(event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteEvent(event);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 행사 편집
  void _editEvent(Map<String, dynamic> event) async {
    final detailResult = await _eventService.getEventDetail(event['id']);
    if (!mounted) return;

    if (detailResult['success'] == true) {
      final eventData = detailResult['event'];
      final formData = {
        'id': eventData['id'],
        'title': eventData['title'],
        'siteName': eventData['siteName'],
        'unitCount': eventData['unitCount'],
        'housingTypes': eventData['housingTypes'] ?? [],
        'contractMethod': eventData['contractMethod'],
        'allowOnlineContract': eventData['allowOnlineContract'] ?? true,
        'coverImage': eventData['coverImage'],
        'startDate': eventData['startDate'] != null
            ? DateTime.tryParse(eventData['startDate'].toString())
            : null,
        'endDate': eventData['endDate'] != null
            ? DateTime.tryParse(eventData['endDate'].toString())
            : null,
        'moveInDate': eventData['moveInDate'] != null
            ? DateTime.tryParse(eventData['moveInDate'].toString())
            : null,
      };

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => OrganizerEventFormScreen(event: formData),
        ),
      );
      if (result == true) _loadEvents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detailResult['error'] ?? '행사 정보를 불러올 수 없습니다')),
      );
    }
  }

  // 행사 삭제 확인
  void _confirmDeleteEvent(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('행사 삭제', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          '\'${event['title']}\' 행사를 삭제하시겠습니까?\n\n삭제하면 복구할 수 없습니다.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeletePasswordDialog(event);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제하기'),
          ),
        ],
      ),
    );
  }

  // 삭제용 비밀번호 확인
  void _showDeletePasswordDialog(Map<String, dynamic> event) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('비밀번호 확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '삭제를 위해 본인 계정 비밀번호를 입력해 주세요.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
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

              final deleteResult = await _eventService.deleteEvent(event['id']);
              if (!mounted) return;
              if (deleteResult['success'] == true) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('행사가 삭제되었습니다')),
                );
                _loadEvents();
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text(deleteResult['error'] ?? '행사 삭제에 실패했습니다')),
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

  // 로고 + 역할 뱃지 (주황 배경)
  Widget _buildLogo() {
    final bool isAdmin = _currentRole == AppConstants.roleAdmin;
    final String badgeText = isAdmin ? '관리자' : '주관사';
    // 관리자=빨강, 주관사=주황
    final Color badgeColor = isAdmin ? Colors.red : AppColors.organizer;

    return Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
