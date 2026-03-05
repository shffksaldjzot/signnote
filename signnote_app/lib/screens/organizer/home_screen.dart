import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../widgets/event/event_card.dart';
import '../../services/event_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
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
// - 하단: 마이페이지 아이콘
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
  String _currentRole = 'ORGANIZER'; // 현재 사용자 역할 (관리자/주관사)

  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // 사용자 역할 가져오기
    _loadEvents();   // 화면 열릴 때 행사 목록 불러오기
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
      });
    } else {
      setState(() {
        _error = result['error'] ?? '행사 목록을 불러올 수 없습니다';
        _isLoading = false;
      });
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

        final event = _events[index - 1];  // 인덱스 1부터 행사 카드
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
          onMoreTap: () => _showEventMenu(event),
        );
      },
    );
  }

  // 행사 카드 3점 메뉴 (편집/삭제)
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
            // 행사 편집
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('행사 편집'),
              onTap: () {
                Navigator.pop(context);
                _editEvent(event);
              },
            ),
            // 행사 삭제
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('행사 삭제', style: TextStyle(color: Colors.red)),
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

  // 행사 편집 (기존 등록 폼 재활용, 수정 모드)
  void _editEvent(Map<String, dynamic> event) async {
    // 행사 상세 정보를 가져와서 편집 폼에 전달
    final detailResult = await _eventService.getEventDetail(event['id']);
    if (!mounted) return;

    if (detailResult['success'] == true) {
      final eventData = detailResult['event'];
      // 날짜 문자열을 DateTime으로 변환
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
      // 수정 성공 시 목록 새로고침
      if (result == true) _loadEvents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detailResult['error'] ?? '행사 정보를 불러올 수 없습니다')),
      );
    }
  }

  // 행사 삭제 확인 팝업 → 비밀번호 입력
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

  // 행사 삭제용 비밀번호 확인 팝업
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

              // 비밀번호 확인
              final verifyResult = await _authService.verifyPassword(password);
              if (!mounted) return;
              if (verifyResult['success'] != true) {
                messenger.showSnackBar(
                  SnackBar(content: Text(verifyResult['error'] ?? '비밀번호가 올바르지 않습니다')),
                );
                return;
              }

              // 행사 삭제 API 호출
              final deleteResult = await _eventService.deleteEvent(event['id']);
              if (!mounted) return;
              if (deleteResult['success'] == true) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('행사가 삭제되었습니다')),
                );
                _loadEvents(); // 목록 새로고침
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
