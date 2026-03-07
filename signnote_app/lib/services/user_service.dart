import 'package:dio/dio.dart';
import 'api_service.dart';

// ============================================
// 사용자 관리 서비스 (User Service)
// 주관사/관리자가 전체 사용자 목록을 조회하고
// 관리자가 업체/주관사를 승인/거부할 때 사용
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

  // ---- 사용자 승인 (관리자 전용) ----
  // 업체/주관사 가입 신청을 승인
  Future<Map<String, dynamic>> approveUser(String userId) async {
    try {
      final response = await _api.patch('/users/$userId/approve');
      return {
        'success': true,
        'user': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '승인 처리에 실패했습니다',
      };
    }
  }

  // ---- 비밀번호 초기화 (관리자 전용) ----
  // 무작위 비밀번호로 변경 후 새 비밀번호를 반환
  Future<Map<String, dynamic>> resetPassword(String userId) async {
    try {
      final response = await _api.patch('/users/$userId/reset-password');
      return {
        'success': true,
        'newPassword': response.data['newPassword'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '비밀번호 초기화에 실패했습니다',
      };
    }
  }

  // ---- 본인 비밀번호 변경 (모든 역할) ----
  // 현재 비밀번호 확인 후 새 비밀번호로 변경
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _api.patch('/users/me/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return {
        'success': true,
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '비밀번호 변경에 실패했습니다',
      };
    }
  }

  // ---- 내 프로필 조회 (본인 전체 정보) ----
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _api.get('/users/me');
      return {
        'success': true,
        'user': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '프로필 정보를 불러올 수 없습니다',
      };
    }
  }

  // ---- 내 프로필 수정 (본인 정보 변경) ----
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.patch('/users/me', data: data);
      return {
        'success': true,
        'user': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '프로필 수정에 실패했습니다',
      };
    }
  }

  // ---- 일괄 승인 (관리자 전용) ----
  Future<Map<String, dynamic>> batchApproveUsers(List<String> userIds) async {
    try {
      final response = await _api.post('/users/batch-approve', data: {
        'userIds': userIds,
      });
      return {
        'success': true,
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '일괄 승인 처리에 실패했습니다',
      };
    }
  }

  // ---- 일괄 회원 탈퇴 (관리자 전용) ----
  Future<Map<String, dynamic>> batchDeleteUsers(List<String> userIds) async {
    try {
      final response = await _api.post('/users/batch-delete', data: {
        'userIds': userIds,
      });
      return {
        'success': true,
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '일괄 탈퇴 처리에 실패했습니다',
      };
    }
  }

  // ---- 회원 강제 탈퇴 (관리자 전용) ----
  // 승인된 사용자도 관리자가 강제로 탈퇴시킬 수 있음
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      await _api.delete('/users/$userId');
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '탈퇴 처리에 실패했습니다',
      };
    }
  }

  // ---- 사용자 거부 (관리자 전용) ----
  // 업체/주관사 가입 신청을 거부 (계정 삭제)
  Future<Map<String, dynamic>> rejectUser(String userId) async {
    try {
      final response = await _api.patch('/users/$userId/reject');
      return {
        'success': true,
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '거부 처리에 실패했습니다',
      };
    }
  }
}
