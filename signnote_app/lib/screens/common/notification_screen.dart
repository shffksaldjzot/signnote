import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/notification_service.dart';

// ============================================
// 알림 화면 (Notification Screen)
//
// 구조:
// ┌─ 상단 바 ──────────────────────────────────┐
// | ← 알림                     [전체 읽음]      |
// └────────────────────────────────────────────┘
//
// ┌─ 알림 목록 ─────────────────────────────────┐
// | 🔵 새 계약이 들어왔습니다          방금 전   |
// |    홍길동님이 '줄눈 A'를 계약했습니다.       |
// |─────────────────────────────────────────── |
// | ⚪ 계약 취소가 승인되었습니다      2시간 전   |
// |    '나노코팅 B' 계약이 취소되었습니다.       |
// └────────────────────────────────────────────┘
//
// 데이터: NotificationService
// ============================================

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // 알림 목록 불러오기
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final result = await _notificationService.getNotifications();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _notifications = result['notifications'] ?? [];
        }
      });
    }
  }

  // 전체 읽음 처리
  Future<void> _markAllAsRead() async {
    final result = await _notificationService.markAllAsRead();
    if (result['success'] == true) {
      _loadNotifications(); // 새로고침
    }
  }

  // 개별 읽음 처리
  Future<void> _markAsRead(String id) async {
    await _notificationService.markAsRead(id);
    _loadNotifications(); // 새로고침
  }

  // 알림 종류별 아이콘
  IconData _getIcon(String type) {
    switch (type) {
      case 'CONTRACT_CREATED':
        return Icons.description;
      case 'CONTRACT_CONFIRMED':
        return Icons.check_circle;
      case 'CANCEL_REQUESTED':
        return Icons.warning;
      case 'CANCEL_APPROVED':
        return Icons.cancel;
      case 'CANCEL_REJECTED':
        return Icons.block;
      case 'PAYMENT_COMPLETED':
        return Icons.payment;
      case 'PAYMENT_REFUNDED':
        return Icons.money_off;
      default:
        return Icons.notifications;
    }
  }

  // 알림 종류별 색상
  Color _getColor(String type) {
    switch (type) {
      case 'CONTRACT_CREATED':
      case 'CONTRACT_CONFIRMED':
        return AppColors.primary;
      case 'CANCEL_REQUESTED':
        return Colors.orange;
      case 'CANCEL_APPROVED':
      case 'PAYMENT_REFUNDED':
        return AppColors.priceRed;
      case 'CANCEL_REJECTED':
        return Colors.grey;
      case 'PAYMENT_COMPLETED':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  // 시간 차이 표시 (예: "방금 전", "2시간 전", "3일 전")
  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);

      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${date.month}/${date.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          // 전체 읽음 버튼
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('전체 읽음', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('알림이 없습니다', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final noti = _notifications[index];
                      return _buildNotificationItem(noti);
                    },
                  ),
                ),
    );
  }

  // 알림 항목 위젯
  Widget _buildNotificationItem(Map<String, dynamic> noti) {
    final type = noti['type']?.toString() ?? '';
    final isRead = noti['isRead'] == true;
    final icon = _getIcon(type);
    final color = _getColor(type);
    final timeAgo = _timeAgo(noti['createdAt']?.toString());

    return InkWell(
      onTap: () {
        if (!isRead) {
          _markAsRead(noti['id']?.toString() ?? '');
        }
      },
      child: Container(
        // 안 읽은 알림: 연한 파란 배경
        color: isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘 + 읽음 표시
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(icon, color: color, size: 20),
                ),
                // 안 읽은 알림: 파란 점 표시
                if (!isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // 제목 + 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          noti['title'] ?? '',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    noti['body'] ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
