// 카카오(다음) 주소검색 - 플랫폼별 분기
// 웹에서만 실제 동작, 모바일에서는 null 반환
export 'kakao_address_stub.dart'
    if (dart.library.html) 'kakao_address_web.dart';
