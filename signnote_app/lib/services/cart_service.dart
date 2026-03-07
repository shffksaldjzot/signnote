import 'package:dio/dio.dart';
import 'api_service.dart';

// ============================================
// 장바구니 서비스 (Cart Service)
// 장바구니 조회/추가/삭제 API를 호출
//
// 쉽게 말하면: "장바구니 관련 서버 통신 담당"
// - 장바구니 목록 보기
// - 상품 담기/빼기
// - 장바구니 비우기
// ============================================

class CartService {
  final ApiService _api = ApiService();

  // 내 장바구니 조회 (행사별)
  Future<Map<String, dynamic>> getCartItems({String? eventId}) async {
    try {
      final response = await _api.get(
        '/cart',
        queryParams: {
          if (eventId != null) 'eventId': eventId,
        },
      );
      return {
        'success': true,
        'items': response.data,  // 장바구니 항목 배열
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '장바구니를 불러올 수 없습니다',
      };
    }
  }

  // 장바구니에 상품 추가
  Future<Map<String, dynamic>> addItem({
    required String productId,
    required String eventId,
    String? productItemId,
  }) async {
    try {
      final response = await _api.post('/cart/items', data: {
        'productId': productId,
        'eventId': eventId,
        if (productItemId != null) 'productItemId': productItemId,
      });
      return {
        'success': true,
        'item': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '장바구니 추가에 실패했습니다',
      };
    }
  }

  // 장바구니에서 상품 제거
  Future<Map<String, dynamic>> removeItem(String cartItemId) async {
    try {
      await _api.delete('/cart/items/$cartItemId');
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '장바구니 삭제에 실패했습니다',
      };
    }
  }

  // 장바구니 전체 비우기 (행사별)
  Future<Map<String, dynamic>> clearCart(String eventId) async {
    try {
      await _api.delete('/cart/$eventId');
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '장바구니 비우기에 실패했습니다',
      };
    }
  }

  // 장바구니 상품 개수
  Future<int> getCartCount({String? eventId}) async {
    try {
      final response = await _api.get(
        '/cart/count',
        queryParams: {
          if (eventId != null) 'eventId': eventId,
        },
      );
      return response.data['count'] ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
