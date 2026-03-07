// 카카오(다음) 주소검색 - 웹 전용 구현
// index.html에 추가된 openDaumPostcode() JS 함수를 호출
import 'dart:async';
import 'dart:js_interop';

// index.html에 정의된 openDaumPostcode 함수 바인딩
@JS('openDaumPostcode')
external JSPromise _openDaumPostcode();

/// 카카오(다음) 주소검색 팝업을 열고 선택된 주소를 반환
/// 사용자가 선택하지 않거나 오류 발생 시 null 반환
Future<String?> openKakaoAddressSearch() async {
  try {
    final result = await _openDaumPostcode().toDart;
    if (result == null) return null;
    final address = (result as JSString).toDart;
    return address.isEmpty ? null : address;
  } catch (_) {
    return null;
  }
}
