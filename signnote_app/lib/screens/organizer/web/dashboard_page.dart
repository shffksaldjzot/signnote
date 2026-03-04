import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../services/event_service.dart';
import '../event_form_screen.dart';

// ============================================
// 대시보드 메인 페이지 (Dashboard)
//
// 모바일과 동일한 카드 그리드 방식으로 행사 목록 표시
// + 카드를 눌러 행사 생성
// ============================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final EventService _eventService = EventService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // 행사 목록 불러오기
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    final result = await _eventService.getEvents();

    if (result['success'] == true) {
      final List events = result['events'] ?? [];
      _events = events.map<Map<String, dynamic>>((e) {
        return {
          'id': e['id']?.toString() ?? '',
          'title': e['title'] ?? '행사명 없음',
          'coverImage': e['coverImage'],
          'startDate': e['startDate']?.toString(),
          'endDate': e['endDate']?.toString(),
          'entryCode': e['entryCode']?.toString(),
          'siteName': e['siteName'] ?? '',
        };
      }).toList();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // 행사 등록 다이얼로그 (팝업 형태)
  void _showEventFormDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 600,
          height: MediaQuery.of(context).size.height * 0.85,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scaffold(
              body: Stack(
                children: [
                  const OrganizerEventFormScreen(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((result) {
      if (result == true) _loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 페이지 제목 + 행사 등록 버튼 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '행사 목록',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showEventFormDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('행사 등록', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 행사 카드 그리드 (모바일과 동일한 카드 방식) ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,     // 4열 그리드 (웹은 넓으니까)
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _events.length + 1, // +1은 추가 카드
                    itemBuilder: (context, index) {
                      // 마지막은 + 추가 카드
                      if (index == _events.length) {
                        return _buildAddCard();
                      }
                      return _buildEventCard(_events[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 행사 카드 (모바일과 동일한 디자인)
  Widget _buildEventCard(Map<String, dynamic> event) {
    // 커버 이미지 처리
    final coverImage = event['coverImage']?.toString();
    ImageProvider? imageProvider;
    if (coverImage != null && coverImage.startsWith('data:image')) {
      try {
        final base64Str = coverImage.split(',').last;
        imageProvider = MemoryImage(base64Decode(base64Str));
      } catch (_) {}
    } else if (coverImage != null && coverImage.isNotEmpty) {
      imageProvider = NetworkImage(coverImage);
    }

    // D-day 계산
    String dDayText = '';
    try {
      final startStr = event['startDate'];
      if (startStr != null) {
        final start = DateTime.parse(startStr);
        final now = DateTime.now();
        final diff = start.difference(DateTime(now.year, now.month, now.day)).inDays;
        if (diff > 0) {
          dDayText = 'D-$diff';
        } else if (diff == 0) {
          dDayText = 'D-DAY';
        } else {
          dDayText = 'D+${-diff}';
        }
      }
    } catch (_) {}

    return GestureDetector(
      onTap: () {
        final eventId = event['id'] ?? '';
        context.go('/organizer/events/$eventId');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 커버 이미지 (정사각형)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.background,
                image: imageProvider != null
                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                    : null,
              ),
              child: imageProvider == null
                  ? const Center(
                      child: Icon(Icons.image_outlined, size: 40, color: AppColors.textHint),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          // 행사명
          Text(
            event['title'] ?? '-',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // D-day + 참여코드
          Row(
            children: [
              if (dDayText.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    dDayText,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                '코드: ${event['entryCode'] ?? '-'}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // + 추가 카드 (행사 생성)
  Widget _buildAddCard() {
    return GestureDetector(
      onTap: _showEventFormDialog,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.background,
                border: Border.all(color: AppColors.border, width: 2, strokeAlign: BorderSide.strokeAlignInside),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, size: 48, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text(
                      '행사 등록',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('', style: TextStyle(fontSize: 14)), // 높이 맞추기용 빈 텍스트
          const SizedBox(height: 4),
          const Text('', style: TextStyle(fontSize: 12)), // 높이 맞추기용
        ],
      ),
    );
  }
}
