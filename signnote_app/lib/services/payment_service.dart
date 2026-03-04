import 'package:dio/dio.dart';
import 'api_service.dart';

// ============================================
// 결제 서비스 (Payment Service)
// 결제 생성/조회/환불 API를 호출
//
// 쉽게 말하면: "결제 관련 서버 통신 담당"
// - 고객: 계약금 결제, 내 결제 내역 보기, 환불 요청
// - 테스트 모드에서는 바로 결제 완료 처리됨
// ============================================

class PaymentService {
  final ApiService _api = ApiService();

  // 결제 요청 (계약 → 결제)
  // contractId: 결제할 계약 ID
  // method: 결제 수단 (CARD, BANK_TRANSFER, EASY_PAY)
  Future<Map<String, dynamic>> createPayment({
    required String contractId,
    String? method,
  }) async {
    try {
      final response = await _api.post('/payments', data: {
        'contractId': contractId,
        if (method != null) 'method': method,
      });
      return {
        'success': true,
        'payment': response.data,  // 생성된 결제 정보
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '결제에 실패했습니다',
      };
    }
  }

  // 내 결제 목록 조회
  // eventId로 행사별 필터 가능
  Future<Map<String, dynamic>> getMyPayments({String? eventId}) async {
    try {
      final response = await _api.get(
        '/payments',
        queryParams: {
          if (eventId != null) 'eventId': eventId,
        },
      );
      return {
        'success': true,
        'payments': response.data,  // 결제 목록
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '결제 목록을 불러올 수 없습니다',
      };
    }
  }

  // 결제 상세 조회
  Future<Map<String, dynamic>> getPaymentDetail(String paymentId) async {
    try {
      final response = await _api.get('/payments/$paymentId');
      return {
        'success': true,
        'payment': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '결제 정보를 불러올 수 없습니다',
      };
    }
  }

  // 환불 요청
  Future<Map<String, dynamic>> requestRefund(String paymentId) async {
    try {
      final response = await _api.put('/payments/$paymentId/refund');
      return {
        'success': true,
        'payment': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '환불 요청에 실패했습니다',
      };
    }
  }
}
