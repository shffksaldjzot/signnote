import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/event/event_card.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import 'product_manage_screen.dart';
import 'contract_screen.dart';

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
  final int _currentTabIndex = 0;

  // API에서 가져온 행사 목록
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;   // 로딩 중 표시
  String? _error;            // 에러 메시지

  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();

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
      // 서버 응답 데이터를 리스트로 변환
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

  // 참여 코드 입력 다이얼로그 (새 행사 추가용)
  void _showEntryCodeDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '행사 참여 코드 입력',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '주관사로부터 받은 6자리 참여 코드를 입력해 주세요.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
              final code = codeController.text;
              if (code.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('6자리 코드를 입력해 주세요')),
                );
                return;
              }
              // async 전에 미리 참조 저장
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              // 참여 코드로 행사 입장 API 호출
              final result = await _authService.enterEvent(code);
              if (!mounted) return;
              if (result['success'] == true) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('행사에 참여했습니다!')),
                );
                _loadEvents(); // 목록 새로고침
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text(result['error'] ?? '입장에 실패했습니다')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('입장하기'),
          ),
        ],
      ),
    );
  }

  // 탭 클릭 시 화면 이동
  void _onTabChanged(int index) {
    if (index == _currentTabIndex) return; // 같은 탭이면 무시

    switch (index) {
      case 0: // 홈 — 현재 화면이므로 무시
        break;
      case 1: // 계약함
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VendorContractScreen()),
        );
        break;
      case 2: // 마이페이지 (아직 없음)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마이페이지는 준비 중입니다')),
        );
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
              // 행사 카드 그리드 (로딩/에러/데이터 분기)
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      // 하단 탭바 (업체용 3탭)
      bottomNavigationBar: AppTabBar.vendor(
        currentIndex: _currentTabIndex,
        onTap: _onTabChanged,
      ),
    );
  }

  // 본문 영역: 로딩 / 에러 / 행사 목록 분기
  Widget _buildBody() {
    // 로딩 중
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // 에러 발생
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadEvents,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    // 행사 목록 그리드
    return GridView.builder(
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
            onTap: _showEntryCodeDialog,
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
