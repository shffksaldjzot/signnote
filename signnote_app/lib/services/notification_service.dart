import 'package:dio/dio.dart';
import 'api_service.dart';

// ============================================
// 알림 서비스 (Notification Service)
// 앱 내 알림 목록 조회, 읽음 처리, FCM 토큰 등록
//
// 쉽게 말하면: "알림 관련 서버 통신 담당"
// ============================================

class NotificationService {
  final ApiService _api = ApiService();

  // 내 알림 목록 조회 (최근 50개)
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await _api.get('/notifications');
      return {
        'success': true,
        'notifications': response.data, // 알림 목록 배열
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '알림을 불러올 수 없습니다',
      };
    }
  }

  // 안 읽은 알림 개수
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final response = await _api.get('/notifications/unread');
      return {
        'success': true,
        'count': response.data['count'] ?? 0,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'count': 0,
        'error': e.response?.data['message'] ?? '알림 개수를 확인할 수 없습니다',
      };
    }
  }

  // 행사별 안 읽은 알림 개수 (주관사 홈 빨간 뱃지용)
  Future<Map<String, dynamic>> getUnreadCountByEvents() async {
    try {
      final response = await _api.get('/notifications/unread-by-events');
      return {
        'success': true,
        'counts': response.data, // { eventId: count, ... }
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'counts': {},
        'error': e.response?.data['message'] ?? '알림 개수를 확인할 수 없습니다',
      };
    }
  }

  // 알림 읽음 처리
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      await _api.put('/notifications/$notificationId/read');
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '읽음 처리에 실패했습니다',
      };
    }
  }

  // 전체 읽음 처리
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      await _api.put('/notifications/read-all');
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '전체 읽음 처리에 실패했습니다',
      };
    }
  }

  // FCM 토큰 등록 (푸시 알림 받기 위해 서버에 토큰 전송)
  Future<Map<String, dynamic>> registerFcmToken(String token) async {
    try {
      await _api.post('/notifications/fcm-token', data: {'token': token});
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'FCM 토큰 등록에 실패했습니다',
      };
    }
  }
}
