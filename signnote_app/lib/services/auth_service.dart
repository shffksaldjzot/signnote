import 'package:dio/dio.dart';
import 'api_service.dart';

// ============================================
// 인증 서비스 (Auth Service)
// 로그인, 회원가입, 행사 입장 API를 호출하는 서비스
//
// 사용 예시:
//   final result = await AuthService().login('test@test.com', '123456');
//   final result = await AuthService().register({...});
//   final result = await AuthService().enterEvent('123456');
// ============================================

class AuthService {
  final ApiService _api = ApiService();

  // 로그인
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;

      // 토큰 저장 (다음 요청부터 자동으로 사용됨)
      await _api.saveTokens(data['accessToken'], data['refreshToken']);
      // 사용자 정보도 저장 (마이페이지 등에서 사용)
      if (data['user'] != null) {
        await _api.saveUserInfo(Map<String, dynamic>.from(data['user']));
      }

      return {'success': true, 'user': data['user']};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '로그인에 실패했습니다',
      };
    }
  }

  // 회원가입
  // businessNumber: 사업자등록번호 (업체/주관사)
  // businessLicenseImage: 사업자등록증 이미지 URL (업체/주관사)
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? businessNumber,
    String? businessLicenseImage,
  }) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
        'role': role,
        if (businessNumber != null) 'businessNumber': businessNumber,
        if (businessLicenseImage != null) 'businessLicenseImage': businessLicenseImage,
      });

      final data = response.data;

      // 토큰 저장
      await _api.saveTokens(data['accessToken'], data['refreshToken']);
      // 사용자 정보도 저장
      if (data['user'] != null) {
        await _api.saveUserInfo(Map<String, dynamic>.from(data['user']));
      }

      return {'success': true, 'user': data['user']};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '회원가입에 실패했습니다',
      };
    }
  }

  // 행사 입장 (참여 코드)
  Future<Map<String, dynamic>> enterEvent(String entryCode) async {
    try {
      final response = await _api.post('/auth/enter', data: {
        'entryCode': entryCode,
      });

      return {'success': true, 'event': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '유효하지 않은 참여 코드입니다',
      };
    }
  }

  // 로그아웃 (토큰 + 사용자 정보 모두 삭제)
  Future<void> logout() async {
    await _api.clearTokens();
    await _api.clearUserInfo();
  }

  // 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    return _api.isLoggedIn();
  }
}
