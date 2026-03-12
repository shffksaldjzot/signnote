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

  // 주관사용 품목 등록 (vendorId 없이)
  Future<Map<String, dynamic>> createProductByOrganizer({
    required String eventId,
    required String name,
    int? participationFee,
    double? commissionRate,
    double? depositRate,
    String? image,
  }) async {
    try {
      final response = await _api.post('/products/organizer', data: {
        'eventId': eventId,
        'name': name,
        if (participationFee != null) 'participationFee': participationFee,
        if (commissionRate != null) 'commissionRate': commissionRate,
        if (depositRate != null) 'depositRate': depositRate,
        if (image != null) 'image': image,
      });
      return {
        'success': true,
        'product': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '품목 등록에 실패했습니다',
      };
    }
  }

  // 가용 품목 목록 (아직 업체가 선점하지 않은 품목)
  Future<Map<String, dynamic>> getAvailableProducts(String eventId) async {
    try {
      final response = await _api.get('/events/$eventId/products/available');
      return {
        'success': true,
        'products': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '가용 품목을 불러올 수 없습니다',
      };
    }
  }

  // 품목 삭제 (주관사/관리자용 — 1뎁스 품목 삭제)
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      final response = await _api.delete('/products/$productId');
      return {
        'success': true,
        'result': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '품목 삭제에 실패했습니다',
      };
    }
  }

  // 품목 순서 변경 (주관사용)
  Future<Map<String, dynamic>> reorderProducts(
    String eventId,
    List<String> productIds,
  ) async {
    try {
      final response = await _api.patch(
        '/events/$eventId/products/reorder',
        data: {'productIds': productIds},
      );
      return {
        'success': true,
        'result': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '순서 변경에 실패했습니다',
      };
    }
  }

  // 주관사용 업체 참가 취소 (품목에서 업체 해제)
  Future<Map<String, dynamic>> unclaimProduct(String productId) async {
    try {
      final response = await _api.post('/products/$productId/unclaim', data: {});
      return {
        'success': true,
        'product': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '참가 취소에 실패했습니다',
      };
    }
  }

  // 주관사용 업체 배정 (드롭다운에서 업체 선택)
  Future<Map<String, dynamic>> assignVendor({
    required String productId,
    required String vendorId,
  }) async {
    try {
      final response = await _api.post('/products/$productId/assign-vendor', data: {
        'vendorId': vendorId,
      });
      return {
        'success': true,
        'product': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '업체 배정에 실패했습니다',
      };
    }
  }

  // 업체용 품목 선점
  Future<Map<String, dynamic>> claimProduct({
    required String productId,
    required String vendorName,
  }) async {
    try {
      final response = await _api.post('/products/$productId/claim', data: {
        'vendorName': vendorName,
      });
      return {
        'success': true,
        'product': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '품목 선점에 실패했습니다',
      };
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ProductItem (2뎁스 상세 품목) API
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // 상세 품목 목록 조회 (특정 1뎁스 하위)
  Future<Map<String, dynamic>> getProductItems(String productId) async {
    try {
      final response = await _api.get('/products/$productId/items');
      return {
        'success': true,
        'items': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '상세 품목을 불러올 수 없습니다',
      };
    }
  }

  // 상세 품목 등록 (업체가 2뎁스 패키지 추가)
  // images: 이미지 URL 배열 (최대 5장, base64 데이터 URL 지원)
  Future<Map<String, dynamic>> createProductItem({
    required String productId,
    required String name,
    required List<String> housingTypes,
    required int price,
    String? description,
    String? image,
    List<String>? images,
  }) async {
    try {
      final response = await _api.post('/products/$productId/items', data: {
        'name': name,
        'housingTypes': housingTypes,
        'price': price,
        if (description != null) 'description': description,
        if (image != null) 'image': image,
        if (images != null && images.isNotEmpty) 'images': images,
      });
      return {
        'success': true,
        'item': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '상세 품목 등록에 실패했습니다',
      };
    }
  }

  // 상세 품목 수정
  Future<Map<String, dynamic>> updateProductItem(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _api.put('/product-items/$itemId', data: data);
      return {
        'success': true,
        'item': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '상세 품목 수정에 실패했습니다',
      };
    }
  }

  // 상세 품목 삭제
  Future<Map<String, dynamic>> deleteProductItem(String itemId) async {
    try {
      final response = await _api.delete('/product-items/$itemId');
      return {
        'success': true,
        'result': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? '상세 품목 삭제에 실패했습니다',
      };
    }
  }
}
