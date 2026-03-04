import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

// ============================================
// API 서비스 (API Service)
// 앱에서 서버에 데이터를 보내고 받는 도구
//
// 쉽게 말하면: 앱(손님)과 서버(주방) 사이의 "웨이터"
// - 주문(요청)을 서버에 전달하고
// - 음식(응답)을 앱에 가져다줌
// - 통행증(토큰)도 자동으로 붙여서 보냄
// ============================================

class ApiService {
  late final Dio _dio;

  // 싱글톤 (앱 전체에서 하나만 사용)
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConstants.apiBaseUrl}${AppConstants.apiVersion}',
        connectTimeout: const Duration(seconds: 10),  // 연결 제한시간 10초
        receiveTimeout: const Duration(seconds: 10),   // 응답 제한시간 10초
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // 요청/응답 가로채기 (인터셉터)
    _dio.interceptors.add(
      InterceptorsWrapper(
        // 모든 요청에 토큰 자동 첨부
        onRequest: (options, handler) async {
          final token = await _getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        // 401 에러 (토큰 만료) → 자동으로 토큰 갱신 시도
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // 토큰 갱신 성공 → 원래 요청 다시 시도
              final retryResponse = await _dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // ---- 토큰 관리 ----

  // 저장된 Access Token 가져오기
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 토큰 저장
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  // 토큰 삭제 (로그아웃 시)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // 토큰 갱신 시도
  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await saveTokens(
          response.data['accessToken'],
          response.data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // 로그인 되어있는지 확인
  Future<bool> isLoggedIn() async {
    final token = await _getAccessToken();
    return token != null;
  }

  // 사용자 정보 저장 (로그인 성공 시 호출)
  Future<void> saveUserInfo(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', user['name'] ?? '');
    await prefs.setString('user_email', user['email'] ?? '');
    await prefs.setString('user_role', user['role'] ?? '');
    await prefs.setString('user_phone', user['phone'] ?? '');
  }

  // 저장된 사용자 정보 가져오기
  Future<Map<String, String>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    if (name == null) return null;
    return {
      'name': name,
      'email': prefs.getString('user_email') ?? '',
      'role': prefs.getString('user_role') ?? '',
      'phone': prefs.getString('user_phone') ?? '',
    };
  }

  // 사용자 정보 삭제 (로그아웃 시)
  Future<void> clearUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('user_phone');
  }

  // ---- HTTP 요청 메서드 ----

  // GET 요청 (데이터 조회)
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) {
    return _dio.get(path, queryParameters: queryParams);
  }

  // POST 요청 (데이터 생성)
  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  // PUT 요청 (데이터 전체 수정)
  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  // PATCH 요청 (데이터 부분 수정)
  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  // DELETE 요청 (데이터 삭제)
  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
