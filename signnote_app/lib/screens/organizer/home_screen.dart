import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../widgets/event/event_card.dart';
import '../../services/event_service.dart';
import '../../services/api_service.dart';
import 'event_form_screen.dart';
import 'event_manage_screen.dart';

// ============================================
// 주관사 홈 화면
//
// 디자인 참고: 12.주관사용-행사 목록.jpg
// - 상단: Signnote 로고 + "주관사" 뱃지
// - 검색바 + 정렬 드롭다운
// - 행사 카드 그리드 (2열)
// - + 카드를 누르면 행사 생성 폼으로 이동
// - 하단: 마이페이지 아이콘
// ============================================

class OrganizerHomeScreen extends StatefulWidget {
  const OrganizerHomeScreen({super.key});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  // API에서 가져온 행사 목록 (원본)
  List<Map<String, dynamic>> _events = [];
  // 검색/정렬 적용된 행사 목록 (화면에 표시)
  List<Map<String, dynamic>> _filteredEvents = [];
  bool _isLoading = true;
  String? _error;
  String _currentRole = 'ORGANIZER'; // 현재 사용자 역할 (관리자/주관사)

  // 검색어
  final TextEditingController _searchController = TextEditingController();
  // 정렬 기준 (최신순이 기본)
  String _sortBy = 'newest';

  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // 사용자 역할 가져오기
    _loadEvents();   // 화면 열릴 때 행사 목록 불러오기
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            'organizerName': e['organizer']?['name'], // 주관사명
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
        _applyFilter(); // 검색/정렬 적용
      });
    } else {
      setState(() {
        _error = result['error'] ?? '행사 목록을 불러올 수 없습니다';
        _isLoading = false;
      });
    }
  }

  // 검색어와 정렬 기준으로 목록 필터링
  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    // 검색: 행사명 또는 주관사명에 검색어 포함
    List<Map<String, dynamic>> result = _events.where((e) {
      if (query.isEmpty) return true;
      final title = (e['title'] ?? '').toString().toLowerCase();
      final organizer = (e['organizerName'] ?? '').toString().toLowerCase();
      return title.contains(query) || organizer.contains(query);
    }).toList();

    // 정렬
    result.sort((a, b) {
      switch (_sortBy) {
        case 'oldest': // 오래된순
          final aDate = a['startDate'] as DateTime?;
          final bDate = b['startDate'] as DateTime?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        case 'name': // 이름순 (가나다)
          return (a['title'] ?? '').compareTo(b['title'] ?? '');
        case 'newest': // 최신순 (기본)
        default:
          final aDate = a['startDate'] as DateTime?;
          final bDate = b['startDate'] as DateTime?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
      }
    });

    setState(() {
      _filteredEvents = result;
    });
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
              const SizedBox(height: 12),
              // 검색바 + 정렬 드롭다운
              _buildSearchAndSort(),
              const SizedBox(height: 12),
              // 행사 카드 그리드 (로딩/에러/데이터 분기)
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      // 하단: 마이페이지 아이콘 (디자인 가이드라인대로)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 16, right: 24),
        child: Align(
          heightFactor: 1.0, // 자식 크기만큼만 차지 (무한 확장 방지)
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.mypage, extra: _currentRole),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, size: 28, color: AppColors.textSecondary),
                SizedBox(height: 2),
                Text(
                  '마이페이지',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 검색바 + 정렬 드롭다운
  Widget _buildSearchAndSort() {
    return Row(
      children: [
        // 검색바 (행사명/주관사명 검색)
        Expanded(
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(), // 입력할 때마다 필터링
              decoration: InputDecoration(
                hintText: '행사명 검색',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textHint),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 정렬 드롭다운 (최신순/오래된순/이름순)
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              icon: const Icon(Icons.sort, size: 18, color: AppColors.textSecondary),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('최신순')),
                DropdownMenuItem(value: 'oldest', child: Text('오래된순')),
                DropdownMenuItem(value: 'name', child: Text('이름순')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortBy = value);
                  _applyFilter(); // 정렬 변경 시 다시 필터링
                }
              },
            ),
          ),
        ),
      ],
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
      itemCount: _filteredEvents.length + 1,
      itemBuilder: (context, index) {
        // 맨 앞은 + 추가 카드 (주관사는 행사 생성)
        if (index == 0) {
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

        final event = _filteredEvents[index - 1];  // 인덱스 1부터 행사 카드
        return EventCard(
          title: event['title'],
          organizerName: event['organizerName'], // 주관사명 전달
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

  // 로고 + 역할 뱃지 (관리자/주관사 구분)
  Widget _buildLogo() {
    // 관리자면 빨간 뱃지, 주관사면 검정 뱃지
    final bool isAdmin = _currentRole == AppConstants.roleAdmin;
    final String badgeText = isAdmin ? '관리자' : '주관사';
    final Color badgeColor = isAdmin ? Colors.red : AppColors.textPrimary;

    return Row(
      children: [
        // 진짜 로고 이미지 파일 사용
        Image.asset(
          'assets/images/logo.png',
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        // 역할 뱃지 (관리자: 빨강 / 주관사: 검정)
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
