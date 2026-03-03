# Signnote 작업 로그 (WORKLOG)

> 작업 지시, 변경사항, 진행 상황을 시간순으로 기록합니다.
> 새 항목은 항상 아래쪽에 추가합니다.

---

## 작업 로그

### 2026-02-27 — 프로젝트 초기 세팅
- [x] 디자인 분석 보고서 작성 (`research.md`)
- [x] 개발 기획안 작성 (`plan.md`)
- [x] 작업 로그 파일 생성 (`WORKLOG.md`)
- [x] 작업 로그 파일 생성 완료

---

### 2026-02-27 — 용어 수정 지시 (사용자)
> **지시 내용:** 앱 내 용어 통일
- 가구/인테리어 → **입주옵션품목** (유상옵션)
- 임장하기 → **입장하기**
- 입주 박람회 표현 유지

**수정 대상 파일:**
- [x] `research.md` — 용어 수정 반영 (6건 수정 완료)
- [x] `plan.md` — 전체 확인 완료, 이미 "입장" 사용 중이며 "가구/인테리어" 미사용. 수정 불필요
- [x] 메모리(`MEMORY.md`) — 프로젝트 도메인 설명 수정 완료
- [x] `2602271972_사인노트_앱_개발_분석서.md` — 전체 확인 완료, 이미 올바른 용어 사용 중. 수정 불필요

---

### 2026-02-27 — 기술 스택 재검토 (사용자 요청)
> Flutter vs React Native, Node.js vs Java vs Python 비교 분석 수행

**검토 결과:** 현재 기술 스택(Flutter + Node.js/NestJS + PostgreSQL) **유지 결정**
- Flutter: 글로벌 1위(46%), PG 결제 연동 지원, UI 일관성 최고
- Node.js/NestJS: 개발 속도 빠름, 토스페이먼츠 공식 지원
- 리스크: Flutter(Dart) 개발자 풀이 JS 대비 작음 → 코드 문서화로 대비
- [x] 기술 스택 비교 리서치 완료
- [x] 가이드라인 추가: 일반인 눈높이 설명 원칙 (`MEMORY.md`)

---

### 2026-02-27 — 서버/인프라 검토 (사용자 요청)
> AWS 비용이 부담 → 저비용 대안 조사

**검토 결과:**
- AWS (월 9~12만원) → **Vultr 서울 조합 (월 3.4~7.5만원)**으로 변경
- Cloudflare R2/Pages/CDN은 무료로 계속 사용 (보안 우수, 이전 쉬움)
- NestJS는 Cloudflare Workers에서 못 돌림 → 별도 VPS 필요
- 국내 업체(iwinv, Cafe24) 확인했으나 Vultr 서울이 가성비 최고
- 테스트→운영 전환은 나중에 결정해도 됨

- [x] 서버 호스팅 비교 리서치 완료
- [x] `plan.md`에 서버/인프라 구성 섹션 추가 (7. 서버/인프라 구성)

---

### 2026-03-03 — Phase 1: 프로젝트 초기 설정 (진행중)

**Step 1: Flutter 앱 프로젝트 생성 ✅**
- [x] Flutter SDK 설치 (v3.27.4)
- [x] Flutter 프로젝트 생성 (`signnote_app/`)
- [x] 폴더 구조 정리 (screens, widgets, models, providers, services, config)
- [x] 테마 설정 (`config/theme.dart`) — 색상, 버튼, 입력필드, 탭바 스타일
- [x] 상수 설정 (`config/constants.dart`) — 앱 이름, 역할, 코드 길이
- [x] main.dart 수정 + 코드 에러 검사 통과

**Step 2: NestJS 백엔드 프로젝트 생성 ✅**
- [x] NestJS 프로젝트 생성 (`signnote_server/`)
- [x] 폴더 구조 정리 (auth, users, events, products 등 11개 모듈)
- [x] 핵심 패키지 설치 (JWT, Passport, Prisma, bcrypt, class-validator)
- [x] 서버 main.ts 설정 (API prefix, CORS, 입력값 검증)
- [x] .env 환경 변수 설정

**Step 3: PostgreSQL + Prisma 연동 ✅**
- [x] Prisma 초기화 + DB 스키마 작성 (8개 테이블: User, Event, Product, CartItem, Contract, Payment, Settlement, TaxInvoice)
- [x] Prisma 스키마 검증 통과
- [x] Prisma Client 생성 완료
- [x] PrismaService + PrismaModule 작성 (NestJS 연동)
- [x] AppModule에 ConfigModule + PrismaModule 등록
- [x] TypeScript 빌드 에러 없음 확인
- [ ] 실제 PostgreSQL DB 연결 (Neon 등 클라우드 DB 필요 — 배포 시 연결 예정)

**Step 4: 공통 위젯 만들기 ✅**
- [x] AppButton — 파란 버튼(고객), 검정 버튼(업체/주관사), 테두리 버튼, 뱃지 지원
- [x] AppHeader — 상단 헤더 (← 뒤로가기 + 제목)
- [x] AppTabBar — 하단 탭바 (고객 4탭 / 업체·주관사 3탭)
- [x] PriceText — 빨간색 가격 표시 ("가격 : 700,000원")
- [x] BadgeIcon + DdayBadge — 숫자 뱃지, D-day 뱃지
- [x] AppCard — 카드 컨테이너 (일반 / 어두운 요약바)
- [x] AppModal — 가운데 팝업 + 바텀시트
- [x] HousingTypeRadio / Chips / Badge — 평형 선택 (라디오/칩/뱃지 3종)
- [x] intl 패키지 추가 (숫자 콤마 표시용)
- [x] Flutter analyze 에러 0건 확인

**Step 5: 프로젝트 구조 최종 점검 ✅**
- [x] plan.md 대비 누락 항목 확인 및 보충
- [x] `screens/organizer/` 폴더 추가 (주관사용 화면)
- [x] `widgets/event/event_card.dart` 추가 (행사 카드 + 추가 카드)
- [x] `widgets/product/product_card.dart` 추가 (상품 카드, 고객/업체 겸용)
- [x] `widgets/contract/contract_card.dart` 추가 (계약 카드, 고객/업체 겸용)
- [x] `config/routes.dart` 추가 (화면 경로 이름 정의)
- [x] `assets/images/`, `assets/icons/` 폴더 생성 + 로고 복사
- [x] `pubspec.yaml`에 assets 경로 등록
- [x] Flutter analyze 에러 0건 / TypeScript 빌드 에러 0건

---

### ✅ Phase 1 완료! (2026-03-03)

**Flutter 앱 (signnote_app):**
- 파일 14개 생성, 폴더 16개 구성
- 공통 위젯 10종, 설정 파일 3개, 에셋 1개

**백엔드 서버 (signnote_server):**
- NestJS + Prisma 구성 완료
- DB 스키마 8개 테이블 정의
- 모듈 폴더 11개 준비

---

### 2026-03-03 — Phase 2: 인증 시스템 (진행중)

**백엔드 인증 API ✅**
- [x] Users 모듈 (users.service.ts, users.module.ts, create-user.dto.ts)
- [x] Auth 모듈 (auth.service.ts, auth.controller.ts, auth.module.ts)
- [x] JWT 전략 (jwt.strategy.ts) — 토큰 검증
- [x] 역할 가드 (roles.guard.ts) — RBAC (고객/업체/주관사 접근 제어)
- [x] 로그인/회원가입/토큰갱신/행사입장 API 4개 완성
- [x] AppModule에 AuthModule, UsersModule 등록
- [x] TypeScript 빌드 에러 0건

**앱 인증 화면 ✅**
- [x] 로그인 화면 (login_screen.dart) — 디자인 login.jpg 기준
- [x] 참여 코드 입장 화면 (entry_code_screen.dart) — 6칸 숫자 입력
- [x] main.dart → 로그인 화면을 첫 화면으로 설정
- [x] Flutter analyze 에러 0건

**사용자 지시 반영:**
- [x] 참여 코드는 **숫자 6자리**로 통일 (앱: 숫자키패드, 백엔드: 숫자만 허용 검증)

**회원가입 + API 연동 ✅**
- [x] 회원가입 화면 (register_screen.dart) — 이메일/비밀번호/이름/전화번호/역할/사업자번호
- [x] API 서비스 (api_service.dart) — Dio HTTP 클라이언트 + 토큰 자동 관리
- [x] 인증 서비스 (auth_service.dart) — 로그인/회원가입/입장/로그아웃 API 호출
- [x] 로그인 화면 → API 연동 완료 (성공 시 참여코드 화면으로 이동)
- [x] 회원가입 화면 → API 연동 완료 (성공 시 참여코드 화면으로 이동)
- [x] 토큰 자동 관리 (저장/갱신/삭제) — SharedPreferences 사용
- [x] Dio 패키지 + SharedPreferences 패키지 추가
- [x] Flutter analyze 에러 0건 / TypeScript 빌드 에러 0건

---

### ✅ Phase 2 완료! (2026-03-03)

**백엔드 (signnote_server):**
- Auth API 4개: register, login, refresh, enter
- JWT 토큰 인증 + RBAC 역할 가드
- Users 모듈 (사용자 조회/생성)

**앱 (signnote_app):**
- 로그인 화면 → 회원가입 화면 → 참여코드 입장 화면 (3개 화면 흐름 완성)
- API 서비스 + 인증 서비스 (서버 통신 기반 완성)
- 토큰 자동 관리 (저장/갱신/삭제)

**남은 작업:**
- [ ] GitHub 연결 (사용자 요청)
- [ ] **Phase 3: 핵심 비즈니스 로직 (행사/상품)** (다음 단계)

**⚠️ 나중에 추가해야 할 기능 (사용자 메모):**
- [ ] 주관사 페이지에 **행사 참여 코드 생성/관리 기능** 추가 필요

---

### 2026-03-03 — Phase 3: 핵심 비즈니스 로직 (행사/상품) (진행중)

**백엔드 - 행사(Events) 모듈 ✅**
- [x] CreateEventDto (행사 생성 데이터 검증)
- [x] EventsService (목록/상세/생성/수정/참여코드검색)
- [x] EventsController (GET/POST/PUT /events, 주관사 권한 제한)
- [x] 참여 코드 자동 생성 (숫자 6자리, 중복 검사)
- [x] EventsModule 등록 → AppModule에 연결

**백엔드 - 상품(Products) 모듈 ✅**
- [x] CreateProductDto (상품 등록 데이터 검증)
- [x] ProductsService (행사별조회/상세/등록/수정/업체별조회)
- [x] ProductsController (5개 API, 역할별 접근 제어)
- [x] ProductsModule 등록 → AppModule에 연결
- [x] TypeScript 빌드 에러 0건

**앱 - API 서비스 ✅**
- [x] EventService (event_service.dart) — 행사 목록/상세/생성/수정 API 호출
- [x] ProductService (product_service.dart) — 상품 목록/상세/등록/수정/내 상품 API 호출

**앱 - 고객용 화면 ✅**
- [x] CustomerHomeScreen (home_screen.dart) — 행사 목록 그리드 2열, 로고+역할뱃지
- [x] EventDetailScreen (event_detail_screen.dart) — 카테고리별 상품 목록, 타입 선택, 장바구니 토글, 상세 바텀시트

**앱 - 업체(협력업체)용 화면 ✅**
- [x] VendorHomeScreen (home_screen.dart) — 행사 목록 + "협력업체" 뱃지
- [x] VendorProductManageScreen (product_manage_screen.dart) — 내 품목 관리, 수정 아이콘
- [x] VendorProductFormScreen (product_form_screen.dart) — 상품 추가/수정 폼 (카테고리/상품명/설명/가격/타입/이미지)

**앱 - 주관사용 화면 ✅**
- [x] OrganizerHomeScreen (home_screen.dart) — 행사 목록 + "주관사" 뱃지 + 행사 추가
- [x] OrganizerEventFormScreen (event_form_screen.dart) — 행사 등록/수정 폼 (참여코드 자동생성 알림)
- [x] OrganizerEventManageScreen (event_manage_screen.dart) — 행사 관리 + 참여코드 표시/복사

- [x] Flutter analyze 에러 0건 / TypeScript 빌드 에러 0건

---

### ✅ Phase 3 완료! (2026-03-03)

**백엔드 (signnote_server):**
- Events API 4개: 목록, 상세, 생성(참여코드 자동생성), 수정
- Products API 5개: 행사별조회, 상세, 등록, 수정, 내상품조회
- RBAC 적용: 주관사만 행사 생성, 업체만 상품 등록

**앱 (signnote_app):**
- API 서비스 2개: EventService, ProductService
- 고객 화면 2개: 홈(행사목록), 행사상세(품목리스트)
- 업체 화면 3개: 홈, 품목관리, 품목추가/수정폼
- 주관사 화면 3개: 홈, 행사등록폼(참여코드생성), 행사관리(참여코드표시)

**남은 작업:**
- [ ] GitHub 연결 (사용자 요청)
- [ ] **Phase 4: 장바구니 + 계약** (다음 단계)
- [ ] 앱 화면 ↔ API 실제 연동 (현재 임시 데이터 사용 중)

**⚠️ 나중에 추가해야 할 기능 (사용자 메모):**
- [ ] 주관사 페이지에 **행사 참여 코드 생성/관리 기능** 추가 → ✅ Phase 3에서 구현 완료!

---

### 2026-03-03 — Phase 4: 장바구니 + 계약

**백엔드 - 장바구니(Carts) 모듈 ✅**
- [x] AddCartItemDto (장바구니 추가 데이터 검증)
- [x] CartsService (조회/추가/삭제/비우기/개수)
- [x] CartsController (5개 API: GET/POST/DELETE + count)
- [x] CartsModule → AppModule에 등록

**백엔드 - 계약(Contracts) 모듈 ✅**
- [x] CreateContractDto (계약 생성 - 여러 상품 동시 계약 지원)
- [x] ContractsService (생성/고객조회/업체조회/행사조회/상세/취소)
- [x] ContractsController (6개 API: 생성/고객목록/업체목록/행사목록/상세/취소)
- [x] 계약금 자동 계산 (상품가격 × 30%)
- [x] 계약 완료 시 장바구니 자동 비우기
- [x] ContractsModule → AppModule에 등록
- [x] TypeScript 빌드 에러 0건

**앱 - API 서비스 ✅**
- [x] CartService (cart_service.dart) — 장바구니 조회/추가/삭제/비우기/개수
- [x] ContractService (contract_service.dart) — 계약 생성/조회/취소 (고객/업체/주관사)

**앱 - 고객용 화면 ✅**
- [x] CartScreen (cart_screen.dart) — 장바구니 목록, 전체선택, 합계 요약, 계약하기
- [x] CustomerContractScreen (contract_screen.dart) — 계약함, 상태뱃지, 합계 요약바
- [x] EventDetailScreen → 장바구니 버튼 연결 완료

**앱 - 업체용 화면 ✅**
- [x] VendorContractScreen (contract_screen.dart) — 계약함, 집계 카드(총계약/금액/취소), 고객정보 표시

- [x] Flutter analyze 에러 0건 / TypeScript 빌드 에러 0건

---

### ✅ Phase 4 완료! (2026-03-03)

**백엔드 (signnote_server):**
- Carts API 5개: 조회, 추가, 삭제, 전체비우기, 개수
- Contracts API 6개: 생성, 고객목록, 업체목록, 행사목록, 상세, 취소
- 계약금 자동 계산 (30%) + 장바구니 자동 비우기

**앱 (signnote_app):**
- API 서비스 2개: CartService, ContractService
- 고객 화면 2개: 장바구니, 계약함
- 업체 화면 1개: 계약함 (고객정보+집계 표시)

**남은 작업:**
- [ ] **Phase 5: PG 결제 연동** — ⏸️ 나중에 진행 (PG사 계약 필요, 구조만 준비해둘 것)
- [ ] **Phase 6: 협력업체용 기능** — Phase 3~4에서 대부분 완성, 취소 요청 기능 남음
- [ ] GitHub 연결 (사용자 요청)
- [ ] 앱 화면 ↔ API 실제 연동 (현재 임시 데이터 사용 중)

---

<!-- 새 항목은 이 아래에 추가 -->
사인노트 로고 자리에는 내가준 파일을 그대로 써줘
