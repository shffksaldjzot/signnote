import 'package:dio/dio.dart';
import 'api_service.dart';

// ============================================
// 정산 서비스 (Settlement Service)
// 업체 정산 내역 조회 + 주관사 정산 관리
//
// 쉽게 말하면: "정산(돈 나눠주기) 서버 통신 담당"
// ============================================

class SettlementService {
  final ApiService _api = ApiService();

  // 내 정산 목록 (업체용)
  Future<Map<String, dynamic>> getMySettlements() async {
    try {
      final response = await _api.get('/settlements/vendor');
      return {
        'success': true,
        'settlements': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '정산 목록을 불러올 수 없습니다',
      };
    }
  }

  // 내 정산 요약 (업체용 - 합계 통계)
  Future<Map<String, dynamic>> getMySummary() async {
    try {
      final response = await _api.get('/settlements/vendor/summary');
      return {
        'success': true,
        'summary': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '정산 요약을 불러올 수 없습니다',
      };
    }
  }

  // 전체 정산 목록 (주관사용)
  Future<Map<String, dynamic>> getAllSettlements({String? status, String? eventId}) async {
    try {
      final response = await _api.get(
        '/settlements',
        queryParams: {
          if (status != null) 'status': status,
          if (eventId != null) 'eventId': eventId,
        },
      );
      return {
        'success': true,
        'settlements': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '정산 목록을 불러올 수 없습니다',
      };
    }
  }

  // 정산 지급 처리 (주관사: PENDING → TRANSFERRED)
  Future<Map<String, dynamic>> transfer(String settlementId) async {
    try {
      final response = await _api.put('/settlements/$settlementId/transfer');
      return {
        'success': true,
        'settlement': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '지급 처리에 실패했습니다',
      };
    }
  }

  // 정산 완료 처리 (주관사: TRANSFERRED → COMPLETED)
  Future<Map<String, dynamic>> complete(String settlementId) async {
    try {
      final response = await _api.put('/settlements/$settlementId/complete');
      return {
        'success': true,
        'settlement': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '완료 처리에 실패했습니다',
      };
    }
  }
}
