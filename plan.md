# Signnote 개발 기획안 (Plan)

> **원칙:** 코딩 전 반드시 사용자 승인을 득한 후 진행. 모든 코드에 한글 주석 작성.

---

## 1. 기술 스택

### 📱 모바일 앱 (고객/협력업체)
| 영역 | 기술 | 이유 |
|------|------|------|
| **프레임워크** | Flutter (Dart) | iOS + Android 단일 코드베이스, 네이티브 성능, 앱 패키징 용이 |
| **상태관리** | Riverpod 또는 Provider | Flutter 생태계 표준, 역할별 상태 분리 용이 |
| **네비게이션** | GoRouter | 선언적 라우팅, 딥링크 지원 |
| **HTTP** | Dio | REST API 통신, 인터셉터 지원 |
| **로컬 저장소** | SharedPreferences / Hive | 토큰 저장, 캐싱 |

### 💻 관리자 웹 (주관사/관리자 PC)
| 영역 | 기술 | 이유 |
|------|------|------|
| **프레임워크** | Flutter Web 또는 React (Next.js) | 코드 재사용(Flutter Web) 또는 웹 최적화(React) |
| **대시보드** | 차트 라이브러리 (fl_chart / recharts) | 매출/정산 시각화 |

### 🖥️ 백엔드 서버
| 영역 | 기술 | 이유 |
|------|------|------|
| **서버** | Node.js + NestJS | PG사 SDK 풍부, 카카오 알림톡 API 연동 용이, TypeScript |
| **ORM** | Prisma | SQL Injection 방지, 타입 안전 |
| **인증** | JWT + Refresh Token | 모바일 앱 인증 최적화 |

### 🗄️ 데이터베이스
| 영역 | 기술 | 이유 |
|------|------|------|
| **메인 DB** | PostgreSQL | 트랜잭션 안전성 (결제/계약), 관계형 데이터 |
| **캐시** | Redis | 세션 관리, 토큰 블랙리스트, 빈번 조회 캐싱 |
| **파일 저장** | AWS S3 또는 Firebase Storage | 상품 이미지, 행사 커버 이미지 |

### 🔌 외부 연동
| 영역 | 기술 | 용도 |
|------|------|------|
| **PG 결제** | KG이니시스 / 토스페이먼츠 | 계약금 결제 + 지급대행(정산 분배) |
| **세금계산서** | 팝빌 (Popbill) API | 전자세금계산서 자동 발행 + 위수탁 발행 |
| **알림톡** | 카카오 비즈메시지 | 계약/결제/취소 알림 |
| **푸시** | Firebase Cloud Messaging (FCM) | 앱 푸시 알림 |

---

## 2. 프로젝트 구조

### 2-1. Flutter 앱 (모바일)

```
signnote_app/
├── lib/
│   ├── main.dart                     # 앱 진입점
│   ├── app.dart                      # MaterialApp 설정
│   ├── config/
│   │   ├── routes.dart               # GoRouter 라우팅 설정
│   │   ├── theme.dart                # 테마 (컬러, 타이포그래피)
│   │   └── constants.dart            # 상수 (API URL 등)
│   ├── models/                       # 데이터 모델
│   │   ├── user.dart
│   │   ├── event.dart
│   │   ├── product.dart
│   │   ├── cart.dart
│   │   └── contract.dart
│   ├── providers/                    # 상태관리 (Riverpod)
│   │   ├── auth_provider.dart
│   │   ├── event_provider.dart
│   │   ├── cart_provider.dart
│   │   └── contract_provider.dart
│   ├── services/                     # API 통신
│   │   ├── api_service.dart          # Dio 기본 설정
│   │   ├── auth_service.dart
│   │   ├── event_service.dart
│   │   ├── product_service.dart
│   │   └── payment_service.dart
│   ├── screens/                      # 화면
│   │   ├── splash/                   # 스플래시
│   │   ├── onboarding/               # 온보딩 + 코드 입장
│   │   ├── customer/                 # 고객용 화면 (8화면)
│   │   │   ├── home_screen.dart
│   │   │   ├── type_select_screen.dart
│   │   │   ├── event_list_screen.dart
│   │   │   ├── event_detail_screen.dart
│   │   │   ├── product_detail_screen.dart
│   │   │   ├── cart_screen.dart
│   │   │   ├── payment_screen.dart
│   │   │   └── contract_screen.dart
│   │   ├── vendor/                   # 협력업체용 화면 (5화면)
│   │   │   ├── home_screen.dart
│   │   │   ├── event_list_screen.dart
│   │   │   ├── product_manage_screen.dart
│   │   │   ├── product_form_screen.dart
│   │   │   └── contract_screen.dart
│   │   └── mypage/                   # 마이페이지
│   │       └── mypage_screen.dart
│   └── widgets/                      # 공통 위젯
│       ├── common/
│       │   ├── app_button.dart       # 파란/검정 버튼
│       │   ├── app_card.dart         # 카드 컨테이너
│       │   ├── app_modal.dart        # 모달/바텀시트
│       │   ├── price_text.dart       # 빨간 가격 텍스트
│       │   └── badge_icon.dart       # 뱃지 아이콘
│       ├── layout/
│       │   ├── app_header.dart       # 상단 헤더
│       │   └── app_tab_bar.dart      # 하단 탭바
│       ├── event/
│       │   └── event_card.dart       # 행사 카드
│       ├── product/
│       │   ├── product_card.dart     # 상품 카드
│       │   └── housing_type_selector.dart  # 평형 선택
│       └── contract/
│           └── contract_card.dart    # 계약 카드
├── assets/                           # 이미지, 폰트
├── pubspec.yaml                      # Flutter 의존성
└── android/ & ios/                   # 네이티브 설정
```

### 2-2. 백엔드 서버

```
signnote_server/
├── src/
│   ├── main.ts                       # NestJS 진입점
│   ├── app.module.ts                 # 루트 모듈
│   ├── auth/                         # 인증 모듈
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── jwt.strategy.ts
│   │   └── roles.guard.ts           # RBAC 가드
│   ├── users/                        # 사용자 모듈
│   ├── events/                       # 행사 모듈
│   ├── products/                     # 상품 모듈
│   ├── carts/                        # 장바구니 모듈
│   ├── contracts/                    # 계약 모듈
│   ├── payments/                     # 결제 모듈 (PG 연동)
│   ├── settlements/                  # 정산 모듈 (지급대행)
│   ├── tax-invoices/                 # 세금계산서 모듈 (팝빌)
│   ├── notifications/                # 알림 모듈 (알림톡 + FCM)
│   └── common/                       # 공통 (미들웨어, 필터, 파이프)
├── prisma/
│   └── schema.prisma                 # DB 스키마
├── package.json
└── tsconfig.json
```

### 2-3. 관리자 웹 (추후 결정)

```
signnote_admin/
├── (Flutter Web 또는 React/Next.js 구조)
└── 주관사/관리자용 대시보드
```

---

## 3. 데이터베이스 설계 (PostgreSQL + Prisma)

```prisma
// 사용자
model User {
  id            String    @id @default(uuid())
  email         String    @unique
  password      String                          // 해시 저장
  name          String
  phone         String
  role          Role                             // CUSTOMER, VENDOR, ORGANIZER, ADMIN
  businessNumber String?                         // 사업자번호 (업체용)
  bankAccount   String?                          // 계좌정보 (업체용, 정산용)
  createdAt     DateTime  @default(now())
}

// 행사
model Event {
  id                  String    @id @default(uuid())
  title               String                    // 행사명
  organizerId         String                    // 주관사 ID
  organizerName       String                    // 주관사명
  paymentMethod       String                    // 결제 방식
  unitCount           Int                       // 세대수
  housingTypes        String[]                  // ["74A","74B","84A","84B"]
  coverImage          String?                   // 커버 이미지 URL
  startDate           DateTime                  // 행사 시작일
  endDate             DateTime                  // 행사 종료일
  vendorStartDate     DateTime?                 // 업체 일정 시작
  vendorEndDate       DateTime?                 // 업체 일정 종료
  entryCode           String    @unique         // 참여 코드
  allowOnlineContract Boolean   @default(false) // 온라인 계약 허용
  status              EventStatus               // UPCOMING, ACTIVE, ENDED
  createdAt           DateTime  @default(now())
}

// 상품
model Product {
  id            String    @id @default(uuid())
  name          String                          // 상품명
  eventId       String                          // 소속 행사
  vendorId      String                          // 소속 업체
  vendorName    String                          // 업체명
  housingType   String                          // 주거 타입 (84A 등)
  image         String?                         // 상품 이미지 URL
  description   String?                         // 상품 설명
  price         Int                             // 가격 (원)
  discountRate  Float     @default(0)           // 할인율 (0~1)
  createdAt     DateTime  @default(now())
}

// 장바구니
model CartItem {
  id            String    @id @default(uuid())
  userId        String                          // 고객 ID
  productId     String                          // 상품 ID
  eventId       String                          // 행사 ID
  quantity      Int       @default(1)
  addedAt       DateTime  @default(now())
}

// 계약
model Contract {
  id              String          @id @default(uuid())
  customerId      String                        // 고객 ID
  customerName    String                        // 고객명
  productId       String                        // 상품 ID
  eventId         String                        // 행사 ID
  vendorId        String                        // 업체 ID
  originalPrice   Int                           // 원가
  discountAmount  Int                           // 할인액
  finalPrice      Int                           // 최종가
  status          ContractStatus                // PENDING, CONFIRMED, CANCELLED
  createdAt       DateTime        @default(now())
}

// 결제
model Payment {
  id              String          @id @default(uuid())
  contractId      String                        // 계약 ID
  pgTransactionId String?                       // PG 거래번호
  amount          Int                           // 결제금액
  method          String                        // 결제수단 (카드/계좌이체)
  status          PaymentStatus                 // PENDING, COMPLETED, FAILED, REFUNDED
  paidAt          DateTime?
  createdAt       DateTime        @default(now())
}

// 정산
model Settlement {
  id              String          @id @default(uuid())
  paymentId       String                        // 결제 ID
  vendorId        String                        // 업체 ID
  amount          Int                           // 정산 금액
  fee             Int                           // 수수료
  status          SettlementStatus              // PENDING, TRANSFERRED, COMPLETED
  transferDate    DateTime?                     // 지급일
  createdAt       DateTime        @default(now())
}

// 세금계산서
model TaxInvoice {
  id              String          @id @default(uuid())
  settlementId    String                        // 정산 ID
  vendorId        String                        // 공급자 (업체)
  buyerId         String                        // 공급받는자
  amount          Int                           // 공급가액
  taxAmount       Int                           // 세액
  issueType       String                        // 정발행/위수탁
  ntsApprovalNo   String?                       // 국세청 승인번호
  status          TaxInvoiceStatus              // DRAFT, ISSUED, NTS_REPORTED
  issuedAt        DateTime?
  createdAt       DateTime        @default(now())
}
```

---

## 4. 개발 단계 (Phase)

### Phase 1: 프로젝트 초기 설정 ✅ (2026-03-03 완료)
- [x] Flutter 프로젝트 생성 (signnote_app)
- [x] NestJS 백엔드 프로젝트 생성 (signnote_server)
- [x] PostgreSQL + Prisma 설정
- [x] 공통 테마/스타일 설정 (colors, typography)
- [x] 프로젝트 구조 잡기

### Phase 2: 인증 시스템 ✅ (2026-03-03 완료)
- [x] JWT 인증 API (회원가입/로그인/토큰 갱신)
- [x] 역할 기반 접근 제어 (RBAC: 고객/업체/주관사/관리자)
- [x] 참여 코드 입력 → 행사 입장 로직
- [x] Flutter 인증 화면 (온보딩/코드입장)

### Phase 3: 핵심 비즈니스 로직 (행사/상품) ✅ (2026-03-03 완료)
- [x] 행사 CRUD API
- [x] 상품 CRUD API
- [x] 행사 목록/상세 화면 (Flutter)
- [x] 상품 목록/상세 화면 (Flutter)
- [x] 평형 선택 기능

### Phase 4: 장바구니/계약 ✅ (2026-03-03 완료)
- [x] 장바구니 API + 화면
- [x] 계약 생성 API + 화면
- [x] 계약함 화면 (고객용 + 업체용)

### Phase 5: PG 결제 연동 ⬜
- [ ] PG사 선정 및 계약 (KG이니시스 또는 토스페이먼츠)
- [ ] 결제 API 연동 (Flutter 결제 SDK)
- [ ] 결제 완료 처리 + Webhook
- [ ] 결제 화면 구현

### Phase 6: 협력업체용 기능 ⬜
- [ ] 품목 등록/수정 화면
- [ ] 계약함 관리 (집계 + 건별 관리)
- [ ] 취소 요청 기능

### Phase 7: 정산 분배 (지급대행) ⬜
- [ ] PG사 지급대행 서비스 연동
- [ ] 업체별 정산 데이터 생성
- [ ] 정산 분배 API
- [ ] 정산 관리 화면

### Phase 8: 세금계산서 자동 발행 ⬜
- [ ] 팝빌 API 연동
- [ ] 계약 완료 시 세금계산서 자동 생성
- [ ] 위수탁 발행 로직
- [ ] 국세청 자동 신고

### Phase 9: 주관사/관리자 웹 ⬜
- [ ] 관리자 웹 프로젝트 설정
- [ ] 행사 생성/관리 대시보드
- [ ] 품목 관리 화면
- [ ] 매출/계약/정산 대시보드
- [ ] 사용자 관리

### Phase 10: 알림 시스템 ⬜
- [ ] FCM 푸시 알림 연동
- [ ] 카카오 알림톡 연동
- [ ] 알림 발송 로직 (계약/결제/취소 이벤트)

### Phase 11: 마무리 및 배포 ⬜
- [ ] UI/UX 다듬기
- [ ] 보안 점검 (SSL, 암호화, RBAC 검증)
- [ ] 앱 패키징 (APK/IPA 빌드)
- [ ] 앱스토어/플레이스토어 제출
- [ ] 서버 배포
- [ ] 통합 테스트

---

## 5. 핵심 위젯/컴포넌트 목록 (Flutter)

### 공통 위젯
| 위젯 | 설명 |
|------|------|
| `AppButton` | 파란색/검정색 주요 버튼 |
| `AppCard` | 카드 컨테이너 |
| `AppModal` | 모달/바텀시트 |
| `AppHeader` | 상단 네비게이션 (뒤로가기 + 제목) |
| `AppTabBar` | 하단 탭 네비게이션 (4탭) |
| `BadgeIcon` | 빨간 숫자 뱃지 |
| `PriceText` | 빨간색 가격 표시 |

### 도메인 위젯
| 위젯 | 설명 |
|------|------|
| `EventCard` | 행사 카드 (이미지 + D-day + 날짜) |
| `ProductCard` | 상품 카드 (이미지 + 이름 + 가격) |
| `ProductDetailSheet` | 상품 상세 바텀시트 |
| `HousingTypeSelector` | 평형 선택 모달 |
| `CartItemTile` | 장바구니 아이템 |
| `CartSummary` | 할인/결제 요약 |
| `ContractCard` | 계약 카드 |

---

## 6. API 엔드포인트 (주요)

### 인증
| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | /auth/register | 회원가입 |
| POST | /auth/login | 로그인 |
| POST | /auth/refresh | 토큰 갱신 |
| POST | /auth/enter | 참여코드 입장 |

### 행사
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | /events | 행사 목록 |
| GET | /events/:id | 행사 상세 |
| POST | /events | 행사 생성 (주관사) |
| PUT | /events/:id | 행사 수정 |

### 상품
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | /events/:eventId/products | 상품 목록 |
| GET | /products/:id | 상품 상세 |
| POST | /products | 상품 등록 (업체) |
| PUT | /products/:id | 상품 수정 |

### 장바구니
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | /cart | 장바구니 조회 |
| POST | /cart/items | 장바구니 추가 |
| DELETE | /cart/items/:id | 장바구니 삭제 |

### 계약/결제
| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | /contracts | 계약 생성 |
| GET | /contracts | 계약 목록 |
| POST | /payments | 결제 요청 |
| POST | /payments/webhook | PG 결제 완료 콜백 |

### 정산/세금계산서
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | /settlements | 정산 목록 |
| POST | /settlements/distribute | 정산 분배 실행 |
| POST | /tax-invoices/issue | 세금계산서 발행 |

---

## 7. 서버/인프라 구성

### 7-1. 테스트/개발 단계 (무료)
| 구성 | 서비스 | 비용 |
|------|--------|------|
| 백엔드 서버 | Oracle Cloud Always Free (서울) | 무료 |
| DB (PostgreSQL) | Neon Free | 무료 |
| 캐시 (Redis) | Upstash Free | 무료 |
| 이미지 저장소 | Cloudflare R2 (10GB) | 무료 |
| 관리자 웹 호스팅 | Cloudflare Pages | 무료 |
| 보안/CDN | Cloudflare (DDoS 방어, SSL) | 무료 |

### 7-2. 운영 단계 (월 약 3.4~7.5만원)
| 구성 | 서비스 | 월 비용 |
|------|--------|---------|
| 백엔드 서버 | Vultr 서울 (2vCPU/4GB) | ~3.4만원 |
| DB (PostgreSQL) | Neon Free → Pro ($19) | 0 ~ 2.7만원 |
| 캐시 (Redis) | Upstash Free → 종량제 | 0 ~ 1.4만원 |
| 이미지 저장소 | Cloudflare R2 | 무료~ |
| 관리자 웹 호스팅 | Cloudflare Pages | 무료 |
| 보안/CDN | Cloudflare (DDoS 방어, SSL) | 무료 |

> **참고:** 모바일 앱은 앱스토어/플레이스토어에 올리므로 별도 서버 불필요.
> 운영 서버는 테스트 완료 후 전환하며, 필요 시 다른 서버로 이전 가능.

---

## 8. 현재 상태

- ✅ 디자인 가이드라인 분석 완료
- ✅ 개발 분석서 반영 완료 (PG, 정산, 세금계산서)
- ✅ research.md 작성 완료
- ✅ plan.md 작성 완료
- ✅ **Phase 1: 프로젝트 초기 설정** (2026-03-03 완료)
- ✅ **Phase 2: 인증 시스템** (2026-03-03 완료)
- ✅ **Phase 3: 핵심 비즈니스 로직 (행사/상품)** (2026-03-03 완료)
- ✅ **Phase 4: 장바구니/계약** (2026-03-03 완료)
- ⬜ **Phase 5: PG 결제 연동** (다음 단계)

---

## 9. 기술 스택 선정 사유 요약

| 기존 제안 | 변경 | 이유 |
|-----------|------|------|
| Next.js (웹) | **Flutter (모바일 앱)** | 고객/업체는 모바일 중심, 앱 패키징 필수 |
| Tailwind CSS | **Flutter 내장 UI** | Flutter는 자체 위젯 시스템 사용 |
| Firebase Firestore | **PostgreSQL** | 결제/정산의 트랜잭션 안전성 필요 |
| Zustand | **Riverpod** | Flutter 생태계 표준 상태관리 |
| Firebase Auth | **JWT + NestJS** | PG/정산/세금계산서 등 복잡한 백엔드 로직 필요 |
