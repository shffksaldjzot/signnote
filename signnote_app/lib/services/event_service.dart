import 'package:dio/dio.dart';
import 'api_service.dart';

// ============================================
// 행사 서비스 (Event Service)
// 행사 목록 조회, 상세 조회, 생성, 수정 API를 호출
//
// 쉽게 말하면: "행사 관련 서버 통신 담당"
// - 고객: 행사 목록 보기, 행사 상세 보기
// - 주관사: 행사 만들기, 행사 수정하기
// ============================================

class EventService {
  final ApiService _api = ApiService();

  // 행사 목록 조회
  Future<Map<String, dynamic>> getEvents() async {
    try {
      final response = await _api.get('/events');
      return {
        'success': true,
        'events': response.data,  // 행사 목록 배열
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '행사 목록을 불러올 수 없습니다',
      };
    } catch (e) {
      // DioException 외 예상치 못한 에러도 안전하게 처리
      return {
        'success': false,
        'error': '행사 목록을 불러올 수 없습니다',
      };
    }
  }

  // 행사 상세 조회 (상품 목록 포함)
  Future<Map<String, dynamic>> getEventDetail(String eventId) async {
    try {
      final response = await _api.get('/events/$eventId');
      return {
        'success': true,
        'event': response.data,  // 행사 상세 + 상품 목록
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '행사 정보를 불러올 수 없습니다',
      };
    }
  }

  // 행사 생성 (주관사만 가능)
  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String startDate,
    required String endDate,
    String? siteName,
    int? unitCount,
    String? moveInDate,
    List<String>? housingTypes,
    String? coverImage,
    String? contractMethod,
    bool? allowOnlineContract,
    String? cancelDeadlineStart,
    String? cancelDeadlineEnd,
  }) async {
    try {
      final response = await _api.post('/events', data: {
        'title': title,
        'startDate': startDate,
        'endDate': endDate,
        if (siteName != null) 'siteName': siteName,
        if (unitCount != null) 'unitCount': unitCount,
        if (moveInDate != null) 'moveInDate': moveInDate,
        if (housingTypes != null) 'housingTypes': housingTypes,
        if (coverImage != null) 'coverImage': coverImage,
        if (contractMethod != null) 'contractMethod': contractMethod,
        if (allowOnlineContract != null) 'allowOnlineContract': allowOnlineContract,
        if (cancelDeadlineStart != null) 'cancelDeadlineStart': cancelDeadlineStart,
        if (cancelDeadlineEnd != null) 'cancelDeadlineEnd': cancelDeadlineEnd,
      });

      return {
        'success': true,
        'event': response.data,  // 생성된 행사 정보 (참여코드 포함)
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '행사 생성에 실패했습니다',
      };
    }
  }

  // 행사 삭제 (주관사/관리자만 가능)
  Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    try {
      await _api.delete('/events/$eventId');
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '행사 삭제에 실패했습니다',
      };
    }
  }

  // 행사 참가 취소 (업체/고객)
  Future<Map<String, dynamic>> leaveEvent(String eventId) async {
    try {
      await _api.delete('/events/$eventId/leave');
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '참가 취소에 실패했습니다',
      };
    }
  }

  // 행사 수정 (주관사만 가능)
  Future<Map<String, dynamic>> updateEvent(String eventId, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/events/$eventId', data: data);
      return {
        'success': true,
        'event': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '행사 수정에 실패했습니다',
      };
    }
  }
}
