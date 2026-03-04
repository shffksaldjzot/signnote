import 'package:dio/dio.dart';
import 'api_service.dart';

// ============================================
// 상품 서비스 (Product Service)
// 상품(품목) 목록 조회, 등록, 수정 API를 호출
//
// 쉽게 말하면: "상품 관련 서버 통신 담당"
// - 고객: 행사별 상품 목록 보기
// - 업체: 내 상품 등록/수정/조회
// ============================================

class ProductService {
  final ApiService _api = ApiService();

  // 행사별 상품 목록 조회
  // housingType: 평형 필터 (예: '84A')
  Future<Map<String, dynamic>> getProductsByEvent(
    String eventId, {
    String? housingType,
  }) async {
    try {
      final response = await _api.get(
        '/events/$eventId/products',
        queryParams: {
          if (housingType != null) 'housingType': housingType,
        },
      );
      return {
        'success': true,
        'products': response.data,  // 상품 목록 배열
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '상품 목록을 불러올 수 없습니다',
      };
    }
  }

  // 상품 상세 조회
  Future<Map<String, dynamic>> getProductDetail(String productId) async {
    try {
      final response = await _api.get('/products/$productId');
      return {
        'success': true,
        'product': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '상품 정보를 불러올 수 없습니다',
      };
    }
  }

  // 상품 등록 (업체용)
  Future<Map<String, dynamic>> createProduct({
    required String eventId,
    required String name,
    required String category,
    required String vendorName,
    required List<String> housingTypes,
    required int price,
    String? description,
    String? image,
    double? commissionRate,
    int? participationFee,
  }) async {
    try {
      final response = await _api.post('/products', data: {
        'eventId': eventId,
        'name': name,
        'category': category,
        'vendorName': vendorName,
        'housingTypes': housingTypes,
        'price': price,
        if (description != null) 'description': description,
        if (image != null) 'image': image,
        if (commissionRate != null) 'commissionRate': commissionRate,
        if (participationFee != null) 'participationFee': participationFee,
      });

      return {
        'success': true,
        'product': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '상품 등록에 실패했습니다',
      };
    }
  }

  // 상품 수정 (업체용)
  Future<Map<String, dynamic>> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _api.put('/products/$productId', data: data);
      return {
        'success': true,
        'product': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '상품 수정에 실패했습니다',
      };
    }
  }

  // 전체 상품 목록 조회 (주관사/관리자용)
  // eventId, category로 필터 가능
  Future<Map<String, dynamic>> getAllProducts({
    String? eventId,
    String? category,
  }) async {
    try {
      final response = await _api.get(
        '/products',
        queryParams: {
          if (eventId != null) 'eventId': eventId,
          if (category != null) 'category': category,
        },
      );
      return {
        'success': true,
        'products': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '전체 상품 목록을 불러올 수 없습니다',
      };
    }
  }

  // 내가 등록한 상품 목록 (업체용)
  Future<Map<String, dynamic>> getMyProducts({String? eventId}) async {
    try {
      final response = await _api.get(
        '/products/vendor/mine',
        queryParams: {
          if (eventId != null) 'eventId': eventId,
        },
      );
      return {
        'success': true,
        'products': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '내 상품 목록을 불러올 수 없습니다',
      };
    }
  }
}
