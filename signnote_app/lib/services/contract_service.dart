import 'package:dio/dio.dart';
import 'api_service.dart';

// ============================================
// 계약 서비스 (Contract Service)
// 계약 생성/조회/취소 API를 호출
//
// 쉽게 말하면: "계약 관련 서버 통신 담당"
// - 고객: 장바구니에서 계약 신청, 내 계약 보기
// - 업체: 내 상품 계약 목록 보기
// ============================================

class ContractService {
  final ApiService _api = ApiService();

  // 계약 생성 (장바구니 → 계약)
  Future<Map<String, dynamic>> createContracts({
    required List<Map<String, String>> items,  // [{productId, eventId}]
    String? customerAddress,
    String? customerPhone,
  }) async {
    try {
      final response = await _api.post('/contracts', data: {
        'items': items,
        if (customerAddress != null) 'customerAddress': customerAddress,
        if (customerPhone != null) 'customerPhone': customerPhone,
      });
      return {
        'success': true,
        'contracts': response.data,  // 생성된 계약 배열
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '계약 생성에 실패했습니다',
      };
    }
  }

  // 내 계약 목록 조회 (고객용)
  Future<Map<String, dynamic>> getMyContracts({String? eventId}) async {
    try {
      final response = await _api.get(
        '/contracts',
        queryParams: {
          if (eventId != null) 'eventId': eventId,
        },
      );
      return {
        'success': true,
        'contracts': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '계약 목록을 불러올 수 없습니다',
      };
    }
  }

  // 내 상품의 계약 목록 (업체용)
  Future<Map<String, dynamic>> getVendorContracts({String? eventId}) async {
    try {
      final response = await _api.get(
        '/contracts/vendor',
        queryParams: {
          if (eventId != null) 'eventId': eventId,
        },
      );
      return {
        'success': true,
        'contracts': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '계약 목록을 불러올 수 없습니다',
      };
    }
  }

  // 행사별 전체 계약 목록 (주관사용)
  Future<Map<String, dynamic>> getEventContracts(String eventId) async {
    try {
      final response = await _api.get('/contracts/event/$eventId');
      return {
        'success': true,
        'contracts': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '계약 목록을 불러올 수 없습니다',
      };
    }
  }

  // 계약 상세 조회
  Future<Map<String, dynamic>> getContractDetail(String contractId) async {
    try {
      final response = await _api.get('/contracts/$contractId');
      return {
        'success': true,
        'contract': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '계약 정보를 불러올 수 없습니다',
      };
    }
  }

  // 계약 취소
  Future<Map<String, dynamic>> cancelContract(String contractId) async {
    try {
      final response = await _api.put('/contracts/$contractId/cancel');
      return {
        'success': true,
        'contract': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '계약 취소에 실패했습니다',
      };
    }
  }
}
