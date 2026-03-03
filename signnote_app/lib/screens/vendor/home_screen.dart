import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/event/event_card.dart';
import 'product_manage_screen.dart';

// ============================================
// 업체(협력업체) 홈 화면
//
// 디자인 참고: 7.업체용-행사 목록.jpg
// - 상단: Signnote 로고 + "협력업체" 뱃지
// - "행사 목록 >" 제목
// - 행사 카드 그리드 (2열)
// - 카드에 + 버튼 (새 행사 추가 → 참여 코드 입력)
// - 하단: 3탭 네비게이션 (행사/계약함/마이페이지)
// ============================================

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  int _currentTabIndex = 0;

  // TODO: API에서 행사 목록 가져오기 (현재 임시 데이터)
  final List<Map<String, dynamic>> _events = [
    {
      'id': '1',
      'title': '창원 자이 사전 박람회',
      'coverImageUrl': null,
      'startDate': DateTime(2026, 3, 1),
      'endDate': DateTime(2026, 3, 3),
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
              // 로고 + "협력업체" 뱃지
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
                    // 마지막은 + 추가 카드
                    if (index == _events.length) {
                      return AddEventCard(
                        onTap: () {
                          // TODO: 참여 코드 입력 모달 표시
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
                        // 행사 상세(품목 관리) 화면으로 이동
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VendorProductManageScreen(
                              eventId: event['id'],
                              eventTitle: event['title'],
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
      // 하단 탭바 (업체용 3탭)
      bottomNavigationBar: AppTabBar.vendor(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
          // TODO: 탭별 화면 이동
        },
      ),
    );
  }

  // 로고 + "협력업체" 뱃지 (진짜 logo.png 이미지 사용)
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
        // "협력업체" 뱃지
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
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
