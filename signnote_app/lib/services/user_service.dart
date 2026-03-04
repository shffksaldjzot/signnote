import 'package:dio/dio.dart';
import 'api_service.dart';

// ============================================
// 사용자 관리 서비스 (User Service)
// 주관사/관리자가 전체 사용자 목록을 조회할 때 사용
//
// 쉽게 말하면: "회원 관리 서버 통신 담당"
// ============================================

class UserService {
  final ApiService _api = ApiService();

  // 전체 사용자 목록 조회 (주관사/관리자용)
  // role: 'CUSTOMER', 'VENDOR', 'ORGANIZER' 등으로 필터 가능
  Future<Map<String, dynamic>> getUsers({String? role}) async {
    try {
      final response = await _api.get(
        '/users',
        queryParams: {
          if (role != null) 'role': role,
        },
      );
      return {
        'success': true,
        'users': response.data, // 사용자 목록 배열
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '사용자 목록을 불러올 수 없습니다',
      };
    }
  }

  // 사용자 상세 조회 (주관사/관리자용)
  Future<Map<String, dynamic>> getUserDetail(String userId) async {
    try {
      final response = await _api.get('/users/$userId');
      return {
        'success': true,
        'user': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '사용자 정보를 불러올 수 없습니다',
      };
    }
  }
}
