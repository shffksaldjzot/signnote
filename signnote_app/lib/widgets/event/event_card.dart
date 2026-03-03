import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../common/badge_icon.dart';

// ============================================
// EventCard - 행사 카드 위젯
//
// 디자인: 커버 이미지(정사각형) + 행사명 + D-day 뱃지 + 날짜
// 행사 목록 화면에서 그리드 형태로 표시됨
//
// 사용 예시:
//   EventCard(
//     title: '창원 자이 사전 박람회',
//     coverImageUrl: 'https://...',
//     startDate: DateTime(2026, 3, 1),
//     endDate: DateTime(2026, 3, 3),
//     onTap: () {},
//   )
// ============================================

class EventCard extends StatelessWidget {
  final String title;             // 행사명
  final String? coverImageUrl;    // 커버 이미지 URL (없으면 기본 이미지)
  final DateTime startDate;       // 시작일
  final DateTime endDate;         // 종료일
  final VoidCallback? onTap;      // 카드 눌렀을 때
  final VoidCallback? onMoreTap;  // ⋮ 더보기 눌렀을 때

  const EventCard({
    super.key,
    required this.title,
    this.coverImageUrl,
    required this.startDate,
    required this.endDate,
    this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    // D-day 계산 (오늘 기준 남은 일수)
    final now = DateTime.now();
    final daysLeft = startDate.difference(DateTime(now.year, now.month, now.day)).inDays;

    // 날짜 포맷 (예: "2026.03.01~03.03")
    final dateText = '${_formatDate(startDate)}~${_formatDate(endDate)}';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 커버 이미지 (정사각형, 둥근 모서리)
          AspectRatio(
            aspectRatio: 1,  // 1:1 정사각형
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.background,
                image: coverImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              // 이미지가 없으면 기본 아이콘 표시
              child: coverImageUrl == null
                  ? const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: AppColors.textHint,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          // 행사명
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,  // 길면 ... 처리
          ),
          const SizedBox(height: 4),
          // D-day 뱃지 + 날짜 + ⋮ 더보기
          Row(
            children: [
              DdayBadge(daysLeft: daysLeft),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              // ⋮ 더보기 버튼
              if (onMoreTap != null)
                GestureDetector(
                  onTap: onMoreTap,
                  child: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 날짜를 "2026.03.01" 형식으로 변환
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

// ============================================
// AddEventCard - 행사 추가 카드 (+)
//
// 디자인: 회색 배경 + 가운데 + 아이콘
// 행사 목록에서 새 행사를 추가할 때 사용
// ============================================

class AddEventCard extends StatelessWidget {
  final VoidCallback? onTap;

  const AddEventCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.background,
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              size: 32,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
