// ============================================
// Signnote 앱 상수 (변하지 않는 값들)
// API 주소, 앱 이름 등을 한곳에서 관리
// ============================================

class AppConstants {
  // 앱 기본 정보
  static const String appName = 'Signnote';             // 앱 이름
  static const String appNameKo = '사인노트';             // 앱 한글 이름

  // API 서버 주소 (나중에 실제 서버 주소로 변경)
  static const String apiBaseUrl = 'https://signnote.onrender.com'; // Render 배포 서버
  static const String apiVersion = '/api/v1';               // API 버전

  // 참여 코드 길이 (디자인에서 6칸 확인)
  static const int entryCodeLength = 6;

  // 계약금 비율 (디자인에서 확인: 1,400,000원의 30% = 420,000원)
  static const double depositRate = 0.3;                     // 30%

  // 주거 타입 목록 (디자인에서 확인)
  static const List<String> defaultHousingTypes = [
    '74A',
    '74B',
    '84A',
    '84B',
  ];

  // 사용자 역할
  static const String roleCustomer = 'CUSTOMER';      // 고객
  static const String roleVendor = 'VENDOR';           // 협력업체
  static const String roleOrganizer = 'ORGANIZER';     // 주관사
  static const String roleAdmin = 'ADMIN';             // 관리자
}
