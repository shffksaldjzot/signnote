// ============================================
// Signnote 라우팅 설정 (화면 이동 규칙)
//
// 어떤 URL로 가면 어떤 화면을 보여줄지 정하는 파일
// ============================================

/// 앱에서 사용하는 화면 경로 이름 모음
class AppRoutes {
  // 인증 관련
  static const String login = '/login';               // 로그인
  static const String register = '/register';          // 회원가입
  static const String entryCode = '/entry-code';       // 참여 코드 입력

  // 고객용
  static const String customerHome = '/customer/home';           // 고객 홈
  static const String customerEventList = '/customer/events';    // 행사 목록
  static const String customerEventDetail = '/customer/events/:id'; // 행사 상세
  static const String customerCart = '/customer/cart';            // 장바구니
  static const String customerContract = '/customer/contracts';  // 계약함
  static const String customerPayment = '/customer/payment';     // 결제

  // 업체용
  static const String vendorHome = '/vendor/home';               // 업체 홈
  static const String vendorEventList = '/vendor/events';        // 행사 목록
  static const String vendorProductManage = '/vendor/products';  // 품목 관리
  static const String vendorProductForm = '/vendor/products/form'; // 품목 추가/수정
  static const String vendorContract = '/vendor/contracts';      // 계약함

  // 주관사용
  static const String organizerHome = '/organizer/home';         // 주관사 홈
  static const String organizerEventList = '/organizer/events';  // 행사 목록
  static const String organizerEventForm = '/organizer/events/form'; // 행사 추가
  static const String organizerProductManage = '/organizer/products'; // 품목 관리
  static const String organizerContract = '/organizer/contracts'; // 계약함

  // 공통
  static const String mypage = '/mypage';              // 마이페이지
  static const String notifications = '/notifications'; // 알림

  // 관리자(ADMIN) PC 웹 대시보드 — /admin/ 경로
  static const String organizerDashboard = '/admin/dashboard';       // 대시보드 (통계)
  static const String organizerWebEvents = '/admin/events';          // 행사 관리
  static const String organizerWebEventDetail = '/admin/events/:id'; // 행사 상세 (폴더 2뎁스)
  static const String organizerWebProductDetail = '/admin/events/:eventId/products/:productId'; // 품목 상세 (폴더 3뎁스)
  static const String organizerWebUsers = '/admin/users';            // 업체 관리 (주관사+협력업체)
  static const String organizerWebCustomers = '/admin/customers';    // 고객 관리 (행사별)
  static const String organizerWebLogs = '/admin/logs';              // 활동 로그
  static const String organizerWebMypage = '/admin/mypage';          // 마이페이지 (웹)

  // 삭제된 라우트 (행사 상세 안으로 통합)
  // organizerWebContracts → event_detail 계약현황 탭
  // organizerWebProducts → event_detail 품목관리 탭
  // organizerWebSettlements → event_detail 정산관리 탭
}
