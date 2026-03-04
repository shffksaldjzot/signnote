import 'package:dio/dio.dart';
import 'api_service.dart';

// ============================================
// 활동 로그 서비스 (ActivityLog Service)
// 주관사/관리자가 사용자 행동 기록을 조회할 때 사용
// ============================================

class ActivityLogService {
  final ApiService _api = ApiService();

  // 활동 로그 목록 조회
  Future<Map<String, dynamic>> getLogs({
    String? action,
    String? userId,
    int? limit,
  }) async {
    try {
      final response = await _api.get(
        '/activity-logs',
        queryParams: {
          if (action != null) 'action': action,
          if (userId != null) 'userId': userId,
          if (limit != null) 'limit': limit.toString(),
        },
      );
      return {
        'success': true,
        'logs': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '로그를 불러올 수 없습니다',
      };
    }
  }
}
