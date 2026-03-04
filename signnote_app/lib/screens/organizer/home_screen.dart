import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/event/event_card.dart';
import '../../services/event_service.dart';
import 'event_form_screen.dart';
import 'event_manage_screen.dart';

// ============================================
// 주관사 홈 화면
//
// 디자인 참고: 12.주관사용-행사 목록.jpg
// - 상단: Signnote 로고 + "주관사" 뱃지
// - "행사 목록 >" 제목
// - 행사 카드 그리드 (2열)
// - + 카드를 누르면 행사 생성 폼으로 이동
// - 하단: 3탭 네비게이션 (행사/계약함/마이페이지)
// ============================================

class OrganizerHomeScreen extends StatefulWidget {
  const OrganizerHomeScreen({super.key});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  final int _currentTabIndex = 0;

  // API에서 가져온 행사 목록
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;

  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _loadEvents(); // 화면 열릴 때 행사 목록 불러오기
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
            'startDate': e['startDate'] != null
                ? DateTime.tryParse(e['startDate'].toString())
                : null,
            'endDate': e['endDate'] != null
                ? DateTime.tryParse(e['endDate'].toString())
                : null,
            'entryCode': e['entryCode']?.toString(),
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

  // 탭 클릭 시 화면 이동
  void _onTabChanged(int index) {
    if (index == _currentTabIndex) return;

    switch (index) {
      case 0: // 홈 — 현재 화면이므로 무시
        break;
      case 1: // 계약함 (아직 없음)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주관사 계약함은 준비 중입니다')),
        );
        break;
      case 2: // 마이페이지
        context.push(AppRoutes.mypage, extra: 'ORGANIZER');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // 로고 + "주관사" 뱃지
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
              // 행사 카드 그리드 (로딩/에러/데이터 분기)
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      // 하단 탭바 (주관사용 3탭)
      bottomNavigationBar: AppTabBar.organizer(
        currentIndex: _currentTabIndex,
        onTap: _onTabChanged,
      ),
    );
  }

  // 본문 영역: 로딩 / 에러 / 행사 목록 분기
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: _events.length + 1,
      itemBuilder: (context, index) {
        // 마지막은 + 추가 카드 (주관사는 행사 생성)
        if (index == _events.length) {
          return AddEventCard(
            onTap: () async {
              // 행사 생성 폼으로 이동
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const OrganizerEventFormScreen(),
                ),
              );
              // 생성 성공 시 목록 새로고침
              if (result == true) _loadEvents();
            },
          );
        }

        final event = _events[index];
        return EventCard(
          title: event['title'],
          coverImageUrl: event['coverImageUrl'],
          startDate: event['startDate'],
          endDate: event['endDate'],
          onTap: () {
            // 행사 관리 화면으로 이동
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrganizerEventManageScreen(
                  eventId: event['id'],
                  eventTitle: event['title'],
                  entryCode: event['entryCode'],
                ),
              ),
            );
          },
          onMoreTap: () {},
        );
      },
    );
  }

  // 로고 + "주관사" 뱃지 (진짜 logo.png 이미지 사용)
  Widget _buildLogo() {
    return Row(
      children: [
        // 진짜 로고 이미지 파일 사용
        Image.asset(
          'assets/images/logo.png',
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        // "주관사" 뱃지
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '주관사',
            style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
