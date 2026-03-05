import 'dart:convert';
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
  final String? organizerName;    // 주관사명 (누가 개최했는지)
  final String? coverImageUrl;    // 커버 이미지 URL (없으면 기본 이미지)
  final DateTime? startDate;      // 시작일 (null 가능)
  final DateTime? endDate;        // 종료일 (null 가능)
  final VoidCallback? onTap;      // 카드 눌렀을 때
  final VoidCallback? onMoreTap;  // ⋮ 더보기 눌렀을 때

  const EventCard({
    super.key,
    required this.title,
    this.organizerName,
    this.coverImageUrl,
    this.startDate,
    this.endDate,
    this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    // D-day 계산 (날짜가 없으면 0)
    final now = DateTime.now();
    final daysLeft = startDate != null
        ? startDate!.difference(DateTime(now.year, now.month, now.day)).inDays
        : 0;

    // 날짜 포맷 (예: "2026.03.01~03.03")
    final dateText = startDate != null && endDate != null
        ? '${_formatDate(startDate!)}~${_formatDate(endDate!)}'
        : '날짜 미정';

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
                        image: _resolveImage(coverImageUrl!),
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
          // 주관사명 (있을 때만 표시)
          if (organizerName != null) ...[
            const SizedBox(height: 2),
            Text(
              organizerName!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          // D-day 뱃지 + 날짜 + ⋮ 더보기
          Row(
            children: [
              if (startDate != null) ...[
                DdayBadge(daysLeft: daysLeft),
                const SizedBox(width: 6),
              ],
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

  // 이미지 URL 판별 (base64 data URL이면 MemoryImage, 아니면 NetworkImage)
  ImageProvider _resolveImage(String url) {
    if (url.startsWith('data:image')) {
      final base64Str = url.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    }
    return NetworkImage(url);
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
      // EventCard와 동일한 구조 (이미지 + 텍스트 영역)로 높이 맞추기
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // + 버튼 영역 (디자인 가이드: 심플하게 + 아이콘만)
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.background,
              ),
              child: const Center(
                child: Icon(Icons.add, size: 32, color: AppColors.textSecondary),
              ),
            ),
          ),
          // EventCard 아래 텍스트 영역과 높이 맞추기용 빈 공간
          const SizedBox(height: 8),
          const Text('', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
