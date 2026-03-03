import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/event/event_card.dart';
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
  int _currentTabIndex = 0;

  // TODO: API에서 행사 목록 가져오기 (현재 임시 데이터)
  final List<Map<String, dynamic>> _events = [
    {
      'id': '1',
      'title': '창원 자이 사전 박람회',
      'coverImageUrl': null,
      'startDate': DateTime(2026, 3, 1),
      'endDate': DateTime(2026, 3, 3),
      'entryCode': '123456',
    },
  ];

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
              // 행사 카드 그리드
              Expanded(
                child: GridView.builder(
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
                        onTap: () {
                          // 행사 생성 폼으로 이동
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OrganizerEventFormScreen(),
                            ),
                          );
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
                ),
              ),
            ],
          ),
        ),
      ),
      // 하단 탭바 (주관사용 3탭)
      bottomNavigationBar: AppTabBar.organizer(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
          // TODO: 탭별 화면 이동
        },
      ),
    );
  }

  // 로고 + "주관사" 뱃지
  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Center(
            child: Icon(Icons.edit_document, color: AppColors.white, size: 16),
          ),
        ),
        const SizedBox(width: 6),
        RichText(
          text: const TextSpan(children: [
            TextSpan(
              text: 'sign',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            TextSpan(
              text: 'note',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ]),
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
