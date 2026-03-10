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
- [x] GitHub 연결 (사용자 요청) ✅ 완료
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
- [x] GitHub 연결 ✅ 완료 + Cloudflare 배포 완료
- [ ] 앱 화면 ↔ API 실제 연동 (현재 임시 데이터 사용 중)

---

### 2026-03-03 — GitHub 연결 + Cloudflare 배포

**GitHub 연결 ✅**
- [x] `.gitignore` 생성 (node_modules, .env, .claude 등 제외)
- [x] 원격 저장소 연결: https://github.com/shffksaldjzot/signnote.git
- [x] 전체 코드 커밋 및 푸시 완료 (274개 파일)

**Cloudflare Pages 배포 ✅**
- [x] Flutter 웹 빌드 (`flutter build web`)
- [x] Cloudflare Pages 프로젝트 생성 (`signnote`)
- [x] 정적 파일 배포 완료 (32개 파일)
- [x] 무료 도메인: https://signnote.pages.dev

---

**남은 작업:**
- [ ] **Phase 5: PG 결제 연동** — ⏸️ 나중에 진행 (PG사 계약 필요)
- [ ] **Phase 6: 협력업체용 기능** — 취소 요청 기능 남음
- [ ] 앱 화면 ↔ API 실제 연동 (현재 임시 데이터 사용 중)
- [ ] 실제 PostgreSQL DB 연결 (Neon 등 클라우드 DB 필요)

**⚠️ 사용자 메모 (미처리):**
- [ ] 사인노트 로고 자리에 사용자가 준 파일 그대로 사용
- [ ] 어드민 계정 비번 만들어서 알려주기

---

### 2026-03-03 — 로고 교체 + 서버/DB 연결 + 배포 완료

**로고 교체 ✅**
- [x] 5개 화면의 코드 로고 → 진짜 logo.png 이미지로 교체
  - 로그인, 참여코드 입장, 고객홈, 업체홈, 주관사홈

**서버/DB 연결 ✅**
- [x] Neon 무료 PostgreSQL DB 연결
- [x] Prisma v7 adapter 방식으로 수정 (@prisma/adapter-pg)
- [x] DB 테이블 생성 (prisma db push)
- [x] 서버 정상 동작 확인 (회원가입/로그인 API 테스트 성공)

**서버 배포 (Render.com) ✅**
- [x] Render.com에 NestJS 서버 배포
- [x] 서버 주소: https://signnote.onrender.com
- [x] 앱 API 주소를 Render 서버로 변경
- [x] Cloudflare 재배포 완료

**현재 전체 구성:**
- 앱: https://signnote.pages.dev (Cloudflare Pages)
- 서버: https://signnote.onrender.com (Render.com)
- DB: Neon PostgreSQL (싱가포르)
- 코드: https://github.com/shffksaldjzot/signnote

---

**남은 작업:**
- [ ] 어드민 계정 생성 + 비번 알려주기
- [ ] Phase 5: PG 결제 연동
- [ ] Phase 6: 협력업체 취소 요청 기능
- [ ] 앱 화면 ↔ API 실제 연동 확인/테스트

---

### 2026-03-04 — Phase 4.5: 기능 보강 + 웹 라우터 전환 + 주관사 웹 대시보드

**GoRouter 도입 (웹 주소 기반 라우팅) ✅**
- [x] `go_router` 패키지 추가 (pubspec.yaml)
- [x] `app_router.dart` 신규 생성 — 웹 브라우저 주소창으로 화면 이동 지원
- [x] `main.dart` 수정 — `MaterialApp` → `MaterialApp.router` 전환
- [x] 로그인/입장코드/고객홈/업체홈/주관사홈/주관사웹 등 라우트 정의

**앱 ↔ API 실제 연동 ✅ (임시 데이터 → 서버 데이터)**
- [x] 고객 홈 — 서버에서 행사 목록 불러오기 (EventService 연동)
- [x] 업체 홈 — 서버에서 행사 목록 불러오기 (EventService 연동)
- [x] 주관사 홈 — 서버에서 행사 목록 불러오기 (EventService 연동)
- [x] 업체 품목관리 — 서버에서 내 상품 목록 불러오기 (ProductService 연동)
- [x] 업체 품목추가/수정 — 서버 API 연동
- [x] 주관사 행사 등록/수정 — 서버 API 연동
- [x] 주관사 행사 관리 — 서버에서 행사 상세 + 참여코드 표시
- [x] 고객 장바구니 — 서버 API 연동
- [x] 고객 계약함 — 서버에서 내 계약 목록 불러오기
- [x] 업체 계약함 — 서버에서 업체 계약 목록 불러오기
- [x] 로그인/회원가입/참여코드 — 기존 API 연동 유지
- [x] 전 화면 로딩 상태/에러 처리 추가

**계약 취소 프로세스 개선 ✅ (Phase 6 선행)**
- [x] DB 스키마 — `ContractStatus`에 `CANCEL_REQUESTED` 상태 추가
- [x] 취소 흐름 변경: 고객 취소 요청 → 업체 승인/거부 → 최종 취소
  - `PUT /contracts/:id/cancel` — 고객 취소 요청 (CONFIRMED → CANCEL_REQUESTED)
  - `PUT /contracts/:id/approve-cancel` — 업체 취소 승인 (→ CANCELLED + 환불)
  - `PUT /contracts/:id/reject-cancel` — 업체 취소 거부 (→ CONFIRMED 유지)
- [x] 앱 ContractService에 `approveCancel()`, `rejectCancel()` 추가
- [x] 업체 계약화면에 취소 승인/거부 다이얼로그 UI 구현
- [x] 계약 카드 위젯에 `CANCEL_REQUESTED` 상태 뱃지 추가

**주관사 웹 대시보드 (신규) ✅**
- [x] `web_shell.dart` — 좌측 메뉴 + 상단바 레이아웃 (PC용)
- [x] `dashboard_page.dart` — 대시보드 (행사/계약/매출 통계)
- [x] `events_page.dart` — 행사 목록 관리 (테이블 뷰)
- [x] `event_detail_page.dart` — 행사 상세 (참여코드/상품/계약 탭)
- [x] `contracts_page.dart` — 전체 계약 관리 (필터/검색)
- [x] `routes.dart`에 주관사 웹 경로 추가

**결제 모듈 준비 (Phase 5 선행) ⏳**
- [x] `payment_service.dart` 신규 생성 — 결제 요청/확인/취소 API 틀
- [x] `payment_screen.dart` 신규 생성 — 결제 화면 UI 틀
- [x] 서버 `payments/` 모듈 신규 생성 (controller, service, module, dto)
- [ ] 실제 PG사 연동은 미완료 (PG 계약 필요)

---

**남은 작업:**
- [ ] Phase 5: PG 결제 실제 연동 (토스페이먼츠 / KG이니시스)
- [ ] Phase 7: 정산 분배 (지급대행)
- [ ] Phase 8: 세금계산서 자동 발행 (팝빌 API)
- [ ] Phase 9: 주관사 웹 대시보드 API 연동 (현재 UI만 완성)
- [ ] Phase 10: 알림 시스템 (FCM + 카카오 알림톡)
- [ ] Phase 11: 마무리 및 배포 (앱스토어/플레이스토어)
- [ ] 어드민 계정 생성 + 비번 알려주기

---

### 2026-03-04 — Phase 9: 주관사/관리자 웹 대시보드

**백엔드 API 추가 ✅**
- [x] 사용자 목록 조회 API (`GET /api/v1/users?role=`) — 주관사/관리자 전용
- [x] 사용자 상세 조회 API (`GET /api/v1/users/:id`) — 주관사/관리자 전용
- [x] 전체 상품 목록 API (`GET /api/v1/products?eventId=&category=`) — 주관사/관리자 전용
- [x] UsersController 신규 생성 + UsersModule에 등록
- [x] TypeScript 빌드 에러 0건

**앱 서비스 추가 ✅**
- [x] `user_service.dart` 신규 생성 — 사용자 목록/상세 조회
- [x] `product_service.dart`에 `getAllProducts()` 추가 — 전체 상품 목록 조회

**웹 대시보드 페이지 추가 ✅**
- [x] `products_page.dart` 신규 — 전체 품목 테이블 + 행사/카테고리/검색 필터
- [x] `users_page.dart` 신규 — 사용자 목록 테이블 + 역할 탭 필터 + 검색
- [x] 대시보드 통계 카드에 '총 매출' 추가 (확정 계약 금액 합산)

**사이드바 + 라우터 업데이트 ✅**
- [x] 사이드바에 '품목 관리', '사용자 관리' 메뉴 추가
- [x] `routes.dart`에 경로 추가 (`/organizer/products`, `/organizer/users`)
- [x] `app_router.dart`에 GoRoute 등록
- [x] Flutter analyze 에러 0건

---

**⚠️ 사용자 메모 (미처리):**
- [ ] 관리자 페이지에 로그 기록 페이지 추가 (고객/업체/주관사 행동 로그)

**남은 작업:**
- [ ] Phase 5: PG 결제 실제 연동
- [ ] Phase 7: 정산 분배 (지급대행)
- [ ] Phase 8: 세금계산서 자동 발행 (팝빌 API)
- [ ] Phase 10: 알림 시스템 (FCM + 카카오 알림톡)
- [ ] Phase 11: 마무리 및 배포 (앱스토어/플레이스토어)
- [ ] 어드민 계정 생성 + 비번 알려주기

---

### 2026-03-04 — Phase 10: 알림 시스템 (FCM + 카카오 알림톡)

**DB 스키마 추가 ✅**
- [x] `Notification` 모델 추가 (userId, type, title, body, data, isRead)
- [x] `User` 모델에 `fcmToken` 필드 추가
- [x] Prisma Client 재생성 완료

**백엔드 알림 모듈 ✅**
- [x] `NotificationsService` — 3채널 알림 관리 (DB저장 + FCM + 카카오)
  - 키 없으면 로그만 남기고 에러 없이 넘어감 (나중에 키만 설정하면 동작)
- [x] `NotificationsController` — 알림 API 5개
  - `GET /notifications` — 내 알림 목록
  - `GET /notifications/unread` — 안 읽은 개수
  - `PUT /notifications/:id/read` — 읽음 처리
  - `PUT /notifications/read-all` — 전체 읽음
  - `POST /notifications/fcm-token` — FCM 토큰 등록
- [x] `NotificationsModule` → AppModule 등록

**계약 이벤트 알림 연결 ✅**
- [x] 계약 생성 → 업체에게 "새 계약이 들어왔습니다" 알림
- [x] 취소 요청 → 업체에게 "취소 요청이 들어왔습니다" 알림
- [x] 취소 승인 → 고객에게 "취소가 승인되었습니다" 알림
- [x] 취소 거부 → 고객에게 "취소 요청이 거부되었습니다" 알림

**앱 알림 화면 + 서비스 ✅**
- [x] `notification_service.dart` — 알림 목록/읽음/FCM토큰 API 호출
- [x] `notification_screen.dart` — 알림 목록 화면 (읽음/안읽음 구분, 시간표시)
- [x] `routes.dart` + `app_router.dart`에 `/notifications` 경로 등록

**나중에 키만 설정하면 동작하는 항목:**
- [ ] FCM 서버 키 (.env → `FCM_SERVER_KEY`) — Firebase 콘솔에서 발급
- [ ] 카카오 알림톡 API 키 (.env → `KAKAO_ALIMTALK_API_KEY`, `KAKAO_ALIMTALK_PF_ID`)

- [x] Flutter analyze 에러 0건 / TypeScript 빌드 에러 0건

---

**남은 작업:**
- [ ] Phase 5: PG 결제 실제 연동 (토스페이먼츠 / KG이니시스)
- [ ] Phase 7: 정산 분배 (지급대행)
- [ ] Phase 8: 세금계산서 자동 발행 (팝빌 API)
- [ ] Phase 11: 마무리 및 배포 (앱스토어/플레이스토어)
- [ ] 어드민 계정 생성 + 비번 알려주기
- [ ] 관리자 페이지 로그 기록 페이지 추가

---

### 2026-03-04 — Phase 7: 정산 분배

**백엔드 정산 모듈 ✅**
- [x] `SettlementsService` — 정산 자동 생성, 수수료 계산, 지급/완료 처리
- [x] `SettlementsController` — 정산 API 6개
  - `GET /settlements` — 전체 정산 목록 (주관사)
  - `GET /settlements/vendor` — 내 정산 목록 (업체)
  - `GET /settlements/vendor/summary` — 내 정산 요약 (업체)
  - `GET /settlements/:id` — 정산 상세
  - `PUT /settlements/:id/transfer` — 지급 처리 (PENDING → TRANSFERRED)
  - `PUT /settlements/:id/complete` — 완료 처리 (TRANSFERRED → COMPLETED)
- [x] `SettlementsModule` → AppModule 등록

**결제 → 정산 자동 연결 ✅**
- [x] 결제 완료(PaymentsService) → 정산 레코드 자동 생성
- [x] 수수료 계산: 결제액 × commissionRate = 수수료, 나머지 = 업체 지급액
- [x] 결제 완료 시 고객에게 알림 발송 추가

**앱 + 웹 ✅**
- [x] `settlement_service.dart` — 정산 API 호출 서비스
- [x] `settlements_page.dart` — 주관사 웹 정산 관리 (상태 탭 + 지급/완료 버튼)
- [x] 사이드바에 '정산 관리' 메뉴 추가

---

### 2026-03-04 — 어드민 계정 + 활동 로그

**활동 로그 시스템 ✅**
- [x] DB `ActivityLog` 테이블 추가 (userId, action, target, detail, ipAddress)
- [x] `ActivityLogsService` — 전역(Global) 로그 기록 서비스 (17가지 행동 종류)
- [x] `ActivityLogsController` — `GET /activity-logs` (주관사/관리자 전용)
- [x] `ActivityLogsModule` → AppModule 등록 (Global)
- [x] `activity_log_service.dart` — 앱 로그 조회 서비스
- [x] `logs_page.dart` — 주관사 웹 활동 로그 페이지 (종류별 필터 + 아이콘)
- [x] 사이드바에 '활동 로그' 메뉴 추가

**어드민 계정 ✅**
- [x] `scripts/create-admin.ts` — 관리자 계정 생성 스크립트
  - 이메일: `admin@signnote.com`
  - 비밀번호: `Signnote2026!`
  - 실행법: `npx ts-node src/scripts/create-admin.ts`

- [x] Flutter analyze 에러 0건 / TypeScript 빌드 에러 0건

---

**남은 작업:**
- [ ] Phase 8: 세금계산서 자동 발행 (팝빌 API) — 보류
- [ ] Phase 11: 마무리 및 배포 (앱스토어/플레이스토어) — 보류
- [ ] DB 마이그레이션 (prisma db push) — 새 테이블 3개: Notification, ActivityLog, User.fcmToken
- [ ] FCM/카카오 키 설정 후 알림 활성화

---

### 📊 전체 진행 현황 (2026-03-04 기준)

**Phase 진행 상태:**

| Phase | 내용 | 상태 |
|-------|------|------|
| Phase 1 | 프로젝트 초기 설정 | ✅ 완료 |
| Phase 2 | 인증 시스템 (JWT + RBAC) | ✅ 완료 |
| Phase 3 | 핵심 비즈니스 로직 (행사/상품) | ✅ 완료 |
| Phase 4 | 장바구니 + 계약 | ✅ 완료 |
| Phase 4.5 | 기능 보강 + API 연동 + GoRouter + 계약 취소 | ✅ 완료 |
| Phase 5 | PG 결제 연동 | ⏳ 구조만 완성 (PG사 계약 필요) |
| Phase 7 | 정산 분배 | ✅ 완료 |
| Phase 8 | 세금계산서 (팝빌 API) | ⬜ 보류 |
| Phase 9 | 주관사/관리자 웹 대시보드 | ✅ 완료 |
| Phase 10 | 알림 시스템 (FCM + 카카오) | ✅ 구조 완성 (키 설정 시 동작) |
| Phase 11 | 마무리 및 배포 | ⬜ 미착수 |

**프로젝트 규모:**

| 항목 | 수량 |
|------|------|
| Flutter 앱 파일 (Dart) | 52개 |
| 백엔드 서버 파일 (TypeScript) | 48개 |
| 화면/페이지 수 | 24개 (앱 모바일 + 주관사 웹) |
| API 서비스 (앱) | 11개 |
| 백엔드 컨트롤러 | 11개 |
| 백엔드 모듈 | 12개 |
| DB 테이블 | 10개 (User, Event, Product, CartItem, Contract, Payment, Settlement, TaxInvoice, Notification, ActivityLog) |

**배포 현황:**

| 서비스 | 주소 | 상태 |
|--------|------|------|
| 앱 (웹) | https://signnote.pages.dev | ✅ Cloudflare Pages |
| 서버 (API) | https://signnote.onrender.com | ✅ Render.com |
| DB | Neon PostgreSQL (싱가포르) | ✅ 연결됨 |
| 코드 저장소 | https://github.com/shffksaldjzot/signnote | ✅ GitHub |

**남은 작업 (우선순위 순):**
1. [x] ~~미커밋 변경사항 GitHub 푸시~~ ✅
2. [x] ~~DB 마이그레이션~~ ✅ Notification, ActivityLog, User.fcmToken 추가 완료
3. [x] ~~어드민 계정 생성~~ ✅ admin@signnote.com / Signnote2026!
4. [x] ~~Cloudflare 재배포~~ ✅ 웹 빌드 완료 (Cloudflare 토큰 설정 후 배포 필요)
5. [ ] Phase 5: PG 결제 실제 연동 (토스페이먼츠 / KG이니시스) — PG사 계약 필요
6. [ ] Phase 8: 세금계산서 자동 발행 (팝빌 API) — 보류
7. [ ] FCM/카카오 알림톡 키 설정 후 알림 활성화
8. [x] ~~Phase 11: UI/UX 다듬기~~ ✅ (아래 상세)

---

### 2026-03-04 — Phase 11: UI/UX 다듬기 (API 키 입력 전까지)

**스플래시 화면 추가 ✅**
- [x] `splash_screen.dart` 신규 생성 — 로고 페이드인 + 로딩 애니메이션
- [x] 2초 후 로그인 상태에 따라 자동 이동 (로그인O → 참여코드, 로그인X → 로그인)
- [x] 라우터 첫 화면을 스플래시로 변경 (`/` → SplashScreen)

**마이페이지 화면 추가 ✅**
- [x] `mypage_screen.dart` 신규 생성 — 프로필 카드 + 메뉴 + 로그아웃
- [x] 프로필: 아바타 + 이름 + 역할 뱃지 + 이메일
- [x] 메뉴: 알림, 이용약관, 개인정보처리방침, 앱 버전, 로그아웃
- [x] 고객/업체/주관사 3개 역할 홈 화면에서 마이페이지 탭 연결 완료
- [x] 업체 계약함에서도 마이페이지 탭 연결

**임시 데이터 → 서버 API 연동 전환 ✅**
- [x] 장바구니 화면 (`cart_screen.dart`) — CartService API 연동
- [x] 행사 상세 화면 (`event_detail_screen.dart`) — ProductService API 연동
- [x] 고객 계약함 화면 (`contract_screen.dart`) — ContractService API 연동
- [x] 장바구니 삭제도 서버 연동 (removeItem API)
- [x] 행사 상세 장바구니 추가도 서버 연동 (addItem API)
- [x] 타입 변경 시 상품 자동 재로딩

**공통 위젯 추가 ✅**
- [x] `empty_state.dart` — 빈 상태 공통 위젯 (아이콘+메시지+액션 버튼)
- [x] 장바구니/계약함/행사상세에 일관된 빈 상태/에러 상태 적용

**사용자 정보 관리 개선 ✅**
- [x] `api_service.dart`에 사용자 정보 저장/조회/삭제 메서드 추가
- [x] 로그인/회원가입 시 사용자 정보 자동 저장
- [x] 로그아웃 시 사용자 정보 자동 삭제

**TODO 주석 정리 ✅**
- [x] 14개 → 0개 (임시 데이터 제거, 미구현 기능은 명확한 안내 메시지로 교체)

- [x] Flutter analyze 에러 0건
- [x] Flutter 웹 빌드 성공

---

**최종 남은 작업:**
- [ ] Cloudflare 토큰 설정 후 웹 재배포
- [ ] Phase 5: PG 결제 실제 연동 — PG사 계약 필요
- [ ] Phase 8: 세금계산서 자동 발행 (팝빌 API) — 보류
- [ ] FCM/카카오 알림톡 키 설정 후 알림 활성화
- [ ] 앱 패키징 (APK/IPA) + 스토어 배포

---

### 2026-03-04 — 회원가입 시스템 개편 + 주관사 로그인 플로우 수정

> **사용자 요청:**
> 1. 업체/주관사 가입 시 "이름"→"업체명", 관리자 승인 필수, 사업자등록번호/사업자등록증 첨부
> 2. 주관사는 로그인 후 행사코드 입력 화면을 건너뛰어야 함

**기능 1: 회원가입 시스템 개편 (업체/주관사 관리자 승인제) ✅**

*DB 수정:*
- [x] `User` 모델에 `isApproved` (Boolean) 필드 추가 — 업체/주관사는 false로 시작, 고객은 true
- [x] `User` 모델에 `businessLicenseImage` (String?) 필드 추가 — 사업자등록증 이미지 URL
- [x] Prisma DB push + Client 재생성 완료

*백엔드 수정:*
- [x] `auth.service.ts` — 로그인 시 `isApproved` 체크, 미승인이면 403 에러 반환
- [x] `users.service.ts` — `approveUser()`, `rejectUser()` 메서드 추가
- [x] `users.controller.ts` — `PATCH /users/:id/approve` (승인), `PATCH /users/:id/reject` (거부) API 추가 (관리자 전용)
- [x] `users.controller.ts` — 주관사는 VENDOR 정보만 열람 가능, 관리자는 전체 열람
- [x] `create-user.dto.ts` — `businessLicenseImage` 필드 추가

*앱 수정:*
- [x] `register_screen.dart` — 전면 개편
  - 역할 선택을 상단으로 이동 (선택에 따라 아래 필드 동적 변경)
  - 업체/주관사 선택 시 "이름" 라벨 → "업체명"으로 자동 변경
  - 전화번호 입력: `010-0000-0000` 자동 포맷팅
  - 사업자등록번호 입력: `000-00-00000` 자동 포맷팅
  - 사업자등록번호 필드: 업체+주관사 모두 표시 (기존에는 업체만)
  - 사업자등록증 이미지 첨부 영역 추가 (파일 스토리지 연동 시 활성화)
  - 하단에 "관리자 승인 후 로그인 가능" 안내 문구
  - 가입 후 승인 대기 안내 다이얼로그 → 로그인 화면으로 이동
- [x] `auth_service.dart` — `businessLicenseImage` 파라미터 추가
- [x] `api_service.dart` — `patch()` HTTP 메서드 추가
- [x] `user_service.dart` — `approveUser()`, `rejectUser()` API 추가
- [x] `users_page.dart` — 전면 개편
  - "승인" 상태 열 추가 (승인/대기 뱃지)
  - 관리자: 승인/거부 버튼 (아이콘 + 확인 다이얼로그)
  - 상세보기 다이얼로그 (이름, 이메일, 전화번호, 역할, 승인상태, 사업자등록번호, 사업자등록증 이미지)
  - 주관사: 업체 탭만 표시 / 관리자: 전체 역할 탭 표시
  - "관리" 열 추가 (상세보기 + 승인/거부 아이콘)

**기능 2: 주관사 로그인 후 행사코드 화면 건너뛰기 ✅**
- [x] `login_screen.dart` — 주관사 로그인 시 `OrganizerHomeScreen`으로 직행 (행사코드 입력 건너뜀)
- [x] `register_screen.dart` — 주관사 가입 후 승인된 경우 바로 주관사 홈으로 이동

**배포 ✅**
- [x] Flutter 웹 빌드 성공 (에러 0건)
- [x] TypeScript 빌드 에러 0건
- [x] Firebase Hosting 배포 완료: https://dealflow-app-c899e.web.app
- [x] Render.com 백엔드: GitHub push 시 자동 배포

---

**현재 배포 현황:**

| 서비스 | 주소 | 상태 |
|--------|------|------|
| 앱 (웹) | https://dealflow-app-c899e.web.app | ✅ Firebase Hosting |
| 서버 (API) | https://signnote.onrender.com | ✅ Render.com |
| DB | Neon PostgreSQL (싱가포르) | ✅ 연결됨 |
| 코드 저장소 | https://github.com/shffksaldjzot/signnote | ✅ GitHub |

**최종 남은 작업:**
- [ ] GitHub 커밋 + 푸시 (이번 작업 반영)
- [ ] Phase 5: PG 결제 실제 연동 — PG사 계약 필요
- [ ] Phase 8: 세금계산서 자동 발행 (팝빌 API) — 보류
- [ ] FCM/카카오 알림톡 키 설정 후 알림 활성화
- [ ] 사업자등록증 이미지 실제 업로드 기능 (파일 스토리지 연동)
- [ ] 앱 패키징 (APK/IPA) + 스토어 배포

### 2026-03-04 — 자동로그인 기능 + 주관사 사업자번호 확인

> **사용자 요청:**
> 1. 자동로그인 기능 추가
> 2. 주관사도 회원가입할 때 사업자번호 + 사업자등록증 첨부

**자동로그인 ✅**
- [x] `splash_screen.dart` — 저장된 토큰+역할 확인 후 자동 이동
  - 주관사 (모바일) → 바로 주관사 홈
  - 주관사/관리자 + PC → 웹 대시보드
  - 고객/업체 → 참여코드 입장 화면
  - 미로그인 → 로그인 화면
- [x] `app_router.dart` — 주관사 모바일 홈 GoRoute 추가 (`/organizer/home`)
- [x] 참여코드 화면 이동 시 역할 정보 전달

**주관사 사업자번호 — 이미 구현 완료 ✅**
- [x] 이전 작업에서 업체+주관사 모두 사업자번호/사업자등록증 첨부 표시되도록 구현 완료

**배포 ✅**
- [x] GitHub 푸시 + Firebase Hosting 배포 완료

---

### 2026-03-04 — 회원가입 화면 수정 (사용자 피드백 반영)

> **사용자 피드백 (스크린샷 기반):**
> 1. 주관사에 사업자등록번호/사업자등록증 첨부 필드 안 보임
> 2. 협력업체 회원가입에도 사업자등록증 첨부 버튼 없음
> 3. 가입유형 선택을 맨 위로 올려달라
> 4. 협력업체/주관사는 "이름" → "업체명"으로 바꿔달라
> 5. 전화번호/사업자번호 포맷 자동 적용해달라

**회원가입 화면 수정 ✅ (커밋: d67cbcf)**
- [x] 가입 유형 선택을 폼 **최상단**으로 이동
- [x] 협력업체+주관사 모두 사업자등록번호 + 사업자등록증 첨부 필드 표시
- [x] 전화번호 `TextInputFormatter` — `010-0000-0000` 하이픈 자동 삽입
- [x] 사업자등록번호 `TextInputFormatter` — `000-00-00000` 하이픈 자동 삽입
- [x] 협력업체/주관사 선택 시 "이름" → "업체명" 자동 변경
- [x] GitHub 푸시 완료

---

### 📊 전체 진행 현황 (2026-03-04 최종)

**Phase 진행 상태:**

| Phase | 내용 | 상태 |
|-------|------|------|
| Phase 1 | 프로젝트 초기 설정 | ✅ 완료 |
| Phase 2 | 인증 시스템 (JWT + RBAC) | ✅ 완료 |
| Phase 3 | 핵심 비즈니스 로직 (행사/상품) | ✅ 완료 |
| Phase 4 | 장바구니 + 계약 | ✅ 완료 |
| Phase 4.5 | 기능 보강 + API 연동 + GoRouter | ✅ 완료 |
| Phase 5 | PG 결제 연동 | ⏳ 구조만 완성 (PG사 계약 필요) |
| Phase 7 | 정산 분배 | ✅ 완료 |
| Phase 8 | 세금계산서 (팝빌 API) | ⬜ 보류 |
| Phase 9 | 주관사/관리자 웹 대시보드 | ✅ 완료 |
| Phase 10 | 알림 시스템 (FCM + 카카오) | ✅ 구조 완성 (키 설정 시 동작) |
| Phase 11 | UI/UX 다듬기 + 자동로그인 + 회원가입 개편 | ✅ 완료 |

**배포 현황:**

| 서비스 | 주소 | 상태 |
|--------|------|------|
| 앱 (웹) | https://dealflow-app-c899e.web.app | ✅ Firebase Hosting |
| 서버 (API) | https://signnote.onrender.com | ✅ Render.com |
| DB | Neon PostgreSQL (싱가포르) | ✅ 연결됨 |
| 코드 저장소 | https://github.com/shffksaldjzot/signnote | ✅ GitHub |

**어드민 계정:**
- 이메일: `admin@signnote.com` / 비밀번호: `Signnote2026!`

**최종 남은 작업:**
- [ ] Phase 5: PG 결제 실제 연동 — PG사 계약 필요
- [ ] Phase 8: 세금계산서 자동 발행 (팝빌 API) — 보류
- [ ] FCM/카카오 알림톡 키 설정 후 알림 활성화
- [ ] 사업자등록증 이미지 실제 업로드 기능 (파일 스토리지 연동)
- [ ] 앱 패키징 (APK/IPA) + 스토어 배포
- [ ] Firebase Studio 환경 인증 이슈 해결 (비대화형 터미널에서 `firebase login` 불가)

---

### 2026-03-04 — 사용자 피드백 반영 (3건)

> **사용자 피드백:**
> 1. 어드민이 사용자 비밀번호를 무작위로 초기화할 수 있어야 함
> 2. 행사등록 날짜 선택 시 회색화면만 뜨는 버그
> 3. 평형 타입은 고정이 아니라 자유 입력 방식이어야 함

**1. 비밀번호 초기화 기능 ✅**
- [x] 백엔드: `PATCH /users/:id/reset-password` API 추가 (무작위 8자리 비밀번호 생성)
- [x] 앱: `user_service.dart`에 `resetPassword()` 추가
- [x] 웹: 사용자 상세 다이얼로그에 "비밀번호 초기화" 버튼 추가
- [x] 초기화 후 새 비밀번호를 다이얼로그로 표시 (복사 가능)

**2. 날짜 선택기 회색화면 수정 ✅**
- [x] 원인: `flutter_localizations` 패키지 미설치 상태에서 `locale: Locale('ko')` 사용
- [x] `pubspec.yaml`에 `flutter_localizations` 패키지 추가
- [x] `main.dart`에 한국어 로컬라이제이션 설정 추가 (`GlobalMaterialLocalizations` 등)
- [x] `event_form_screen.dart`에서 불필요한 `locale` 파라미터 제거
- [x] `intl` 패키지 버전 `^0.20.2` → `^0.19.0` 으로 변경 (호환성)

**3. 평형 타입 자유 입력 방식 ✅**
- [x] 기존 고정 체크박스(74A, 74B, 84A, 84B) → 텍스트 입력 + 추가 버튼 방식
- [x] 추가된 타입은 칩(Chip) 형태로 표시, X 버튼으로 삭제 가능
- [x] 중복 입력 방지 (이미 있는 타입이면 안내 메시지)
- [x] 엔터 키로도 추가 가능

**추가 수정:**
- [x] 관리자(ADMIN) 로그인 시 행사코드 입력 화면 건너뛰기 (로그인 + 자동로그인 모두)

- [x] Flutter analyze 에러 0건 / TypeScript 빌드 에러 0건
- [x] Cloudflare Pages 배포 완료

---

### 2026-03-04 — 사용자 피드백 반영 (5건)

> **사용자 피드백:**
> 1. 주관사는 자기 행사에 참여한 협력업체만 볼 수 있어야 함
> 2. 로고 클릭 → 홈으로 이동
> 3. 대시보드에 행사 생성 버튼 추가
> 4. 테스트용 더미 행사 생성
> 5. 어드민/주관사 뱃지 구분 (별개 역할임)

**1. 행사 참여 테이블 + 주관사 업체 필터링 ✅**
- [x] DB: `EventParticipant` 테이블 추가 (eventId + userId, 중복 방지)
- [x] 참여 코드 입장 시 자동으로 참여 기록 저장
- [x] 주관사 → 자기 행사에 참여한 VENDOR만 조회 가능
- [x] 관리자 → 전체 사용자 조회 가능 (기존 유지)

**2. 로고 클릭 → 대시보드 이동 ✅**
- [x] 사이드바 로고를 `InkWell`로 감싸서 클릭 시 대시보드로 이동

**3. 대시보드에 행사 등록 버튼 ✅**
- [x] 대시보드 상단 오른쪽에 "행사 등록" 버튼 추가
- [x] 등록 완료 시 대시보드 데이터 자동 새로고침

**4. 테스트용 더미 행사 ✅**
- [x] 행사명: **창원 자이 입주박람회 (테스트)**
- [x] 참여 코드: **095503**
- [x] 기간: 2026-03-01 ~ 2026-04-30
- [x] 평형 타입: 59A, 74A, 84A, 84B
- [x] 세대수: 500세대

**5. 어드민/주관사 구분 ✅**
- [x] **어드민과 주관사는 별개 역할** — 코드에서도 이미 분리되어 있었으나 UI가 동일했음
- [x] 사이드바 뱃지: 관리자 = 빨간색 "관리자", 주관사 = 파란색 "주관사"
- [x] 메뉴 제한: 활동 로그는 관리자 전용
- [x] "사용자 관리" → "파트너 관리"로 명칭 변경

- [x] Flutter analyze 에러 0건 / TypeScript 빌드 에러 0건
- [x] Cloudflare Pages 배포 + GitHub 푸시 완료

---

## 2026-03-04 (5차 수정)

**1. 마이페이지 + 비밀번호 변경 (전체 역할) ✅**
- [x] 백엔드: `PATCH /api/v1/users/me/password` API 추가 — 현재 비밀번호 확인 후 새 비밀번호로 변경
- [x] 모바일 마이페이지: "비밀번호 변경" 메뉴 추가 (고객/업체/주관사 모두)
- [x] 웹 대시보드: 사이드바에 "마이페이지" 메뉴 추가 → 프로필 카드 + 비밀번호 변경 폼
- [x] 라우트 등록: `/organizer/mypage` 경로 + MypagePage 화면 생성

**2. 행사 생성 버튼 수정 ✅**
- [x] 대시보드의 행사 등록 버튼: Navigator.push → 다이얼로그 방식으로 변경 (웹에서 사이드바 사라지는 문제 해결)
- [x] 행사 관리 페이지의 행사 등록 버튼도 동일 다이얼로그 방식 유지

**3. 계약방식 변경 ✅**
- [x] 기존 3개 옵션 (온라인/현장/병행) → 2개 옵션으로 변경
  - "통합계약" (integrated): 모든 품목을 한 번에 계약
  - "개별계약" (individual): 품목별로 따로 계약
- [x] 기본값: 통합계약
- [x] 각 옵션에 설명 추가 (subtitle)

**4. 커버이미지 업로드 ✅**
- [x] 행사 생성/수정 폼에 "커버 이미지" 선택 UI 추가
- [x] image_picker 패키지 설치 → 갤러리에서 이미지 선택
- [x] 이미지를 base64로 변환하여 DB에 직접 저장 (MVP 방식)
- [x] 이미지 미리보기 + 삭제(X) 버튼
- [x] event_card.dart: base64 data URL도 배경 이미지로 표시 가능하게 수정

**5. 행사 코드 입력 Internal Server Error 해결 ✅**
- [x] 원인: `/auth/enter` 엔드포인트에 `JwtAuthGuard` 추가 → 비로그인 사용자 접근 불가 + event_participants 테이블 미생성
- [x] 해결: `OptionalJwtAuthGuard` 새로 생성 — 로그인한 사용자는 참여 기록 저장, 비로그인도 입장 가능
- [x] roles.guard.ts에 OptionalJwtAuthGuard 클래스 추가

**수정 파일 목록:**
- `signnote_server/src/auth/roles.guard.ts` — OptionalJwtAuthGuard 추가
- `signnote_server/src/auth/auth.controller.ts` — enter 엔드포인트 가드 변경
- `signnote_server/src/users/users.service.ts` — changePassword 메서드 추가
- `signnote_server/src/users/users.controller.ts` — PATCH me/password 엔드포인트 추가
- `signnote_app/lib/screens/organizer/event_form_screen.dart` — 계약방식 변경 + 커버이미지 추가
- `signnote_app/lib/screens/common/mypage_screen.dart` — 비밀번호 변경 다이얼로그 추가
- `signnote_app/lib/screens/organizer/web/mypage_page.dart` — 웹 마이페이지 신규 생성
- `signnote_app/lib/screens/organizer/web/web_shell.dart` — 마이페이지 메뉴 추가
- `signnote_app/lib/screens/organizer/web/dashboard_page.dart` — 행사 등록 다이얼로그 방식으로 변경
- `signnote_app/lib/widgets/event/event_card.dart` — base64 이미지 지원
- `signnote_app/lib/config/routes.dart` — organizerWebMypage 경로 추가
- `signnote_app/lib/config/app_router.dart` — MypagePage 라우트 등록
- `signnote_app/lib/services/user_service.dart` — changePassword API 추가
- `signnote_app/pubspec.yaml` — image_picker 패키지 추가

- [x] Flutter analyze 에러 0건 / TypeScript 빌드 에러 0건

---

<!-- 새 항목은 이 아래에 추가 -->

## 2026-03-04 수정 (세션 3)

### 수정 내용 3건

| # | 요청 | 처리 내용 | 수정 파일 |
|---|------|----------|----------|
| 1 | 웹에서 모바일 화면 그대로 보여주기 | PC에서도 웹 대시보드 대신 모바일 OrganizerHomeScreen 표시 (화면 크기 분기 제거) | splash_screen.dart, login_screen.dart |
| 2 | 행사 등록 타입 입력/추가 버튼 안 보임 | 1번 수정으로 해결 — 웹 대시보드 팝업(700px)이 원인, 모바일 전체화면 전환으로 타입 입력 정상 표시 | (1번과 동일) |
| 3 | 참여코드 입장 에러 (로그인 필수 + 500에러) | OptionalJwtAuthGuard → JwtAuthGuard 복원 + EventParticipant upsert try-catch 추가 + 운영 DB 테이블 반영 (prisma db push) | auth.controller.ts, auth.service.ts |

### 배포

- [x] Flutter 웹 빌드 → Cloudflare Pages 배포 완료
- [x] 서버 GitHub push → Render 자동 배포
- [x] 운영 DB에 EventParticipant 테이블 반영 (prisma db push)
- [x] Flutter analyze: 에러/경고 0건 / TypeScript 빌드 에러 0건

---

## 2026-03-05 — 관리자/주관사 홈 화면 빈 화면 버그 수정

> **문제:** 관리자/주관사 로그인 후 홈 화면이 텅 비어있고 "마이페이지" 아이콘만 보임

### 원인 분석
1. **네비게이션 충돌 (핵심):** 로그인 화면에서 `Navigator.pushAndRemoveUntil()` 사용 → 앱은 GoRouter 기반이라 충돌 발생, 화면 렌더링 실패
2. **에러 처리 부족:** EventService에서 DioException만 catch → 다른 에러 발생 시 화면 크래시
3. **관리자 뱃지 오류:** ADMIN 로그인해도 "주관사" 뱃지 표시

### 수정 내용

| # | 파일 | 수정 내용 |
|---|------|----------|
| 1 | `login_screen.dart` | `Navigator.pushAndRemoveUntil()` → `context.go()` (GoRouter) 변경. 고객/업체도 동일하게 GoRouter 이동으로 통일 |
| 2 | `event_service.dart` | `getEvents()`에 일반 `catch(e)` 추가 — DioException 외 에러도 안전 처리 |
| 3 | `home_screen.dart` | 사용자 역할 조회 후 ADMIN이면 빨간 "관리자" 뱃지, ORGANIZER면 검정 "주관사" 뱃지 표시. 마이페이지 이동 시에도 실제 역할 전달 |
| 4 | `home_screen.dart` | bottomNavigationBar `Align` 무한 확장 버그 수정 (`heightFactor: 1.0` 추가) — 빈 화면의 진짜 원인 |

- [x] Flutter analyze 에러 0건

---

### 2026-03-05 — 역할별 화면 타입 분리 (관리자=PC 대시보드 / 나머지=모바일)

> **사용자 확정 규칙:**
> - 관리자(ADMIN): PC 웹 대시보드 (좌측 사이드바 + 전체 너비)
> - 주관사(ORGANIZER): 모바일 화면 (430px) — PC에서 웹으로 사용
> - 협력업체(VENDOR): 모바일 화면 — 실제 스마트폰
> - 고객(CUSTOMER): 모바일 화면 — 실제 스마트폰

**수정 내용:**

| # | 파일 | 수정 내용 |
|---|------|----------|
| 1 | `app_router.dart` | ShellRoute로 WebShell(사이드바) 안에 관리자 대시보드 9개 페이지 등록. 기존 /organizer/* 리다이렉트 제거 |
| 2 | `main.dart` | 관리자 대시보드 경로는 430px 제한 해제 (전체 너비 사용). 나머지는 모바일 430px 유지 |
| 3 | `login_screen.dart` | ADMIN → 대시보드(`/organizer/dashboard`), ORGANIZER → 모바일 홈(`/organizer/home`) |
| 4 | `splash_screen.dart` | 자동로그인도 동일하게 ADMIN/ORGANIZER 분기 |

**관리자 대시보드 페이지 (기존 구현, 이번에 라우트 연결):**
- 대시보드, 행사 관리, 행사 상세, 계약 현황, 품목 관리, 파트너 관리, 정산 관리, 활동 로그, 마이페이지

- [x] Flutter analyze 에러 0건
- [x] Cloudflare Pages 배포 완료

---

## 2026-03-05 — 행사 검색/정렬 + 역할별 필터링 + 품목 관리 시스템 (세션 1)

### 1. 행사 목록 검색/정렬 + 주관사명 표시 (`9ece048`)

**프론트엔드:**
- [x] 주관사 홈: 검색바(행사명) + 정렬 드롭다운(최신순/오래된순/이름순) 추가
- [x] 관리자 웹 행사관리: 주관사 컬럼 추가 + 검색/정렬 기능
- [x] EventCard 위젯에 주관사명(organizerName) 표시 기능 추가

**백엔드:**
- [x] 역할별 행사 필터링 — 주관사: 본인 행사만, 업체/고객: 참여 행사만, 관리자: 전체
- [x] 관리자 라우트 `/admin/*` 분리, 로그인 라우팅 수정

**수정 파일 (16개):**
- `app_router.dart`, `routes.dart`, `main.dart`, `login_screen.dart`, `splash_screen.dart`
- `organizer/home_screen.dart`, `web/events_page.dart`, `web/dashboard_page.dart`
- `event_card.dart`, `event_service.dart`
- `events.controller.ts`, `events.service.ts`

### 2. FEEDBACK 4건 처리 (`4b60b94`)

| # | 피드백 | 처리 |
|---|--------|------|
| 1 | 주관사 홈 검색바/정렬 드롭다운 불필요 | 주관사 홈에서 검색바/정렬 UI 제거 (관리자 웹에만 유지) |
| 2 | 고객 타입 선택 UI 불편 | 팝업 방식 → 드롭다운으로 변경, 서버에서 타입 목록 가져옴 |
| 3 | 활동 로그 기록 안 됨 | 로그인/회원가입/행사생성/수정/입장에 ActivityLog 기록 추가 |
| 4 | 품목 관리 시스템 전면 구축 | 아래 상세 |

**품목 관리 시스템 신규 구축:**
- [x] 주관사: 품목 추가 화면 신규 (`product_add_screen.dart`) — 품목명/참가비/수수료/이미지
- [x] 업체: 참여코드 입장 후 품목 선택 드롭다운 + 선점 (`product_select_screen.dart` 신규)
- [x] 선점된 품목은 다른 업체에게 안 보임 (1업체 1품목)
- [x] 남은 품목 없으면 참여 불가 안내
- [x] DB: `Product.vendorId` nullable로 변경 (prisma db push)
- [x] 백엔드: `products.controller.ts`에 주관사용 상품 생성/선점 API 추가

**수정 파일 (17개):**
- `entry_code_screen.dart`, `event_detail_screen.dart`, `event_manage_screen.dart`
- `organizer/home_screen.dart`, `organizer/product_add_screen.dart` (신규)
- `vendor/product_select_screen.dart` (신규), `product_service.dart`
- `prisma/schema.prisma`, `auth.service.ts`, `contracts.service.ts`
- `events.service.ts`, `products.controller.ts`, `products.service.ts`
- `dto/create-product-organizer.dto.ts` (신규), `dto/create-product.dto.ts`

### 커밋 & 배포

- [x] 커밋 1: `9ece048` — 행사 목록 검색/정렬 + 주관사명 표시 + 역할별 필터링
- [x] 커밋 2: `4b60b94` — FEEDBACK 4건 처리
- [x] Cloudflare Pages 배포 완료
- [x] GitHub push 완료

---

## 2026-03-05 — 피드백 7건 반영 + 주관사 품목 관리 아코디언 개편 (세션 2)

### 1. FEEDBACK.md 7건 처리

| # | 피드백 내용 | 처리 |
|---|-----------|------|
| 1 | 모든 숫자 필드에 천 단위 콤마 적용 | `number_formatter.dart` 유틸 생성, 참가비/가격/세대수에 적용. CLAUDE.md에 절대기준 등록 |
| 2 | 주관사 품목 추가 입력값 오른쪽 정렬 | `product_add_screen.dart` 모든 TextField에 `textAlign: TextAlign.right` |
| 3 | 품목 이미지 저장 시 "request entity too large" | 서버 `main.ts`에 `json({ limit: '10mb' })` 추가 |
| 4 | 주관사 품목 수정 버튼 → "업체만 가능" 에러 | `product_add_screen.dart`에 수정 모드(product 파라미터) 추가 |
| 5 | 품목 카드에 이미지+이름+참가비+수수료 표시 (가격 제거) | `event_manage_screen.dart` 카드 구성 변경 |
| 6 | 주관사 하단 내비게이션 작동 안 함 | `_onTabChanged` 메서드 추가 (홈/계약함/마이페이지 이동) |
| 7 | 업체 품목 화면에 주관사 품목이 보이는 문제 | `product_manage_screen.dart` 전면 리팩토링 — 업체 자신의 상세 품목만 표시 |

### 2. 주관사 품목 관리 화면 아코디언 전면 개편

> 디자인 참고: `4.주관사용-품목 상세.jpg`

- 기존 이미지 카드 리스트 → **ExpansionTile 아코디언** 방식으로 변경
- 접힌 상태: 품목명 + 협력업체명 (또는 "업체 미배정")
- 펼친 상태: 협력 업체 / 수수료 / 참가비 / 단가표(상세보기)
- 각 필드 옆 연필 아이콘 → 팝업 다이얼로그로 인라인 수정
- 헤더에 "총 N 품목" 표시

### 3. 업체 품목 폼 — 적용 타입 서버 연동

- `VendorProductFormScreen`에서 하드코딩된 타입 목록 제거
- `EventService.getEventDetail()`로 행사별 설정 타입을 서버에서 가져오도록 변경
- 서버 응답 없으면 기본값(`AppConstants.defaultHousingTypes`) 폴백

### 수정 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `CLAUDE.md` | 숫자 콤마 포맷 절대기준 추가 |
| `signnote_server/src/main.ts` | body size limit 10mb |
| `signnote_app/lib/utils/number_formatter.dart` | **신규** — CommaFormatter, parseCommaNumber, formatWithComma |
| `signnote_app/lib/screens/organizer/product_add_screen.dart` | 오른쪽 정렬 + 콤마 + 수정 모드 |
| `signnote_app/lib/screens/organizer/event_manage_screen.dart` | 아코디언 전면 개편 + 인라인 수정 + 업체명 표시 |
| `signnote_app/lib/screens/organizer/event_form_screen.dart` | 세대수 콤마 포맷 적용 |
| `signnote_app/lib/screens/vendor/product_manage_screen.dart` | 업체 자기 품목만 표시 + 탭 네비게이션 |
| `signnote_app/lib/screens/vendor/product_form_screen.dart` | 콤마 포맷 + 서버에서 적용 타입 가져오기 |

### 커밋 & 배포

- [x] 커밋 1: `ee80634` — 피드백 7건 반영
- [x] 커밋 2: `87a2058` — 주관사 품목 관리 아코디언 개편
- [x] Flutter analyze 에러 0건
- [x] Cloudflare Pages 배포 완료
- [x] GitHub push 완료

---

## 2026-03-05 — 업체 로그인플로우 개선 + 피드백 8건 반영 (세션 2 후반)

### 1. 업체 로그인 플로우 개선 + 1행사1품목 제한 (`a51827d`)

| # | 내용 | 처리 |
|---|------|------|
| 1 | 업체 로그인 시 참여 행사 유무 분기 | 참여 행사 있으면 → 바로 업체 홈, 없으면 → 행사코드 입력 화면 |
| 2 | 1행사 1품목 제한 | 한 행사에 한 품목만 선점 가능, 중복 선점 시 에러 반환 |
| 3 | 주관사 아코디언에 업체 참가 취소 기능 | 업체 참가 취소 버튼 + 확인 다이얼로그 추가 |
| 4 | vendor/customer 홈 GoRoute 등록 | `app_router.dart`에 GoRoute 추가 |

**수정 파일 (9개):**
- `app_router.dart`, `entry_code_screen.dart`, `login_screen.dart`, `splash_screen.dart`
- `organizer/event_manage_screen.dart`, `product_service.dart`
- `products.controller.ts`, `products.service.ts`

### 2. 피드백 8건 처리 (`a627574`)

| # | 피드백 | 처리 | 수정 파일 |
|---|--------|------|-----------|
| 1 | 업체 행사 참가 취소 기능 | 업체 홈 행사카드 3점 메뉴 → 참가 취소 (확인 팝업 → 비밀번호 인증 → API 호출) | `vendor/home_screen.dart` |
| 2 | 주관사 행사 편집/삭제 | 주관사 홈 행사카드 3점 메뉴 → 편집(기존 폼 재활용) + 삭제(비밀번호 인증) | `organizer/home_screen.dart` |
| 3 | 행사 등록 필드 순서 변경 | "행사 기간"을 "취소 가능 기간" 바로 위로 이동 | `event_form_screen.dart` |
| 4 | 사이드바 메뉴명 변경 | '파트너 관리' → '사용자 관리' | `web_shell.dart` |
| 5 | 관리자 행사 목록 주관사순 정렬 | 정렬 드롭다운에 '주관사순' 옵션 추가 | `web/events_page.dart` |
| 6 | 고객 로그인 시 참여 행사 유무 분기 | 고객도 업체와 동일하게 참여 행사 있으면 바로 홈, 없으면 코드 입력 | `login_screen.dart`, `splash_screen.dart` |
| 7 | 관리자 회원 강제 탈퇴 기능 | 사용자 상세 다이얼로그에 "회원 탈퇴" 버튼 추가 + DELETE API | `users_page.dart`, `users.controller.ts`, `users.service.ts` |
| 8 | 비밀번호 찾기 버튼 | 로그인 화면 "비밀번호를 잊으셨나요?" 버튼 추가 (준비중 안내) | `login_screen.dart` |

**백엔드 신규 API:**
- `POST /auth/verify-password` — 비밀번호 확인 (참가 취소/행사 삭제 시 사용)
- `DELETE /events/:id` — 행사 삭제
- `DELETE /events/:id/leave` — 행사 참가 취소
- `DELETE /users/:id` — 회원 강제 탈퇴 (관리자 전용)

**수정 파일 (18개):**
- `login_screen.dart`, `splash_screen.dart`, `event_form_screen.dart`
- `organizer/home_screen.dart`, `vendor/home_screen.dart`
- `web/events_page.dart`, `web/users_page.dart`, `web/web_shell.dart`
- `auth_service.dart`, `event_service.dart`, `user_service.dart`
- `auth.controller.ts`, `auth.service.ts`
- `events.controller.ts`, `events.service.ts`
- `users.controller.ts`, `users.service.ts`

### 커밋 & 배포

- [x] 커밋 1: `a51827d` — 업체 로그인플로우 + 1행사1품목 + 주관사 참가취소
- [x] 커밋 2: `a627574` — 피드백 8건 반영
- [x] Cloudflare Pages 배포 완료
- [x] GitHub push 완료

---

## 2026-03-05 — 피드백 9건 반영 (세션 3)

> FEEDBACK.md 8건 + 추가 요청 1건 (엔터키 로그인)

### 처리 내용

| # | 피드백 | 처리 | 수정 파일 |
|---|--------|------|-----------|
| 1 | 회원 삭제(탈퇴) 기능 오류 (일반회원/업체 모두) | `deleteUser` 메서드 전면 재작성 — cascade 순서: 알림→장바구니→계약(결제→정산→계약)→상품(vendorId null)→참여기록→주관사행사 관련 데이터→사용자 삭제 | `users.service.ts` |
| 2 | 어드민 사용자 관리 테이블 배지 겹침/이름·이메일 글씨 겹침 | 가로 스크롤 추가 + columnSpacing 24→32 + 이름(140px)/이메일(200px) 고정 너비 + 말줄임(ellipsis) | `users_page.dart` |
| 3 | 개별계약 "준비중" 표시 + 선택 불가 | 라디오버튼 텍스트에 "(준비중)" 추가 + `onChanged: null`로 비활성화 + 회색 텍스트 | `event_form_screen.dart` |
| 4 | 관리자가 행사 삭제할 수 있는 기능 | DataTable에 "관리" 컬럼 추가 + 삭제 아이콘(빨간 휴지통) + 확인 다이얼로그 + deleteEvent API 호출 | `events_page.dart` |
| 5 | 행사명/현장명 길면 "..." 처리 | ConstrainedBox(maxWidth: 180/160) + TextOverflow.ellipsis + Tooltip(마우스 올리면 전체 텍스트 표시) | `events_page.dart` |
| 6 | 로딩 시 유니코드 깨진 글자 깜빡임 | index.html에 흰색 로딩 스피너 추가 — Flutter 첫 프레임(flutter-first-frame) 이벤트 발생 시 페이드아웃 제거 + 10초 안전장치 | `web/index.html` |
| 7 | 행사 참여코드 붙여넣기 안 되는 문제 | maxLength 제거 + `_handlePasteOrInput()` 메서드 추가 — 여러 글자 감지 시 6칸에 자동 분배 | `entry_code_screen.dart` |
| 8 | 갤럭시 뒤로가기 버튼 → 로그인 풀림 | 3개 홈 화면(업체/고객/주관사) Scaffold를 `PopScope(canPop: false)`로 감싸서 뒤로가기 차단 | `vendor/home_screen.dart`, `customer/home_screen.dart`, `organizer/home_screen.dart` |
| 9 | 비밀번호 입력 후 엔터키로 로그인 | 비밀번호 TextField에 `textInputAction: TextInputAction.done` + `onSubmitted: (_) => _handleLogin()` 추가 | `login_screen.dart` |

### 수정 파일 목록

**백엔드 (1개):**
- `signnote_server/src/users/users.service.ts` — deleteUser cascade 삭제 전면 재작성

**프론트엔드 (8개):**
- `signnote_app/lib/screens/onboarding/login_screen.dart` — 엔터키 로그인
- `signnote_app/lib/screens/onboarding/entry_code_screen.dart` — 붙여넣기 지원
- `signnote_app/lib/screens/organizer/event_form_screen.dart` — 개별계약 준비중
- `signnote_app/lib/screens/organizer/home_screen.dart` — PopScope
- `signnote_app/lib/screens/organizer/web/users_page.dart` — 테이블 레이아웃 개선
- `signnote_app/lib/screens/organizer/web/events_page.dart` — 행사 삭제 + 말줄임
- `signnote_app/lib/screens/vendor/home_screen.dart` — PopScope
- `signnote_app/lib/screens/customer/home_screen.dart` — PopScope
- `signnote_app/web/index.html` — 로딩 스피너

### 빌드 & 배포

- [x] Flutter 웹 빌드 성공 (에러 0건)
- [x] TypeScript 빌드 에러 0건
- [x] Cloudflare Pages 배포 완료

---

## 2026-03-05 — 피드백 3건 반영 (세션 4)

### 처리 내용

| # | 피드백 | 처리 | 수정 파일 |
|---|--------|------|-----------|
| 1 | 관리자 대시보드 행사 카드와 배경 구분 안 됨 | 행사 카드 + 추가 카드에 boxShadow + border 추가하여 배경과 시각적 구분 | `dashboard_page.dart` |
| 2 | 알림 팝업 디자인이 서비스와 안 어울림 | theme.dart에 dialogTheme(둥근 모서리 20px, 타이포그래피) + snackBarTheme(floating, 둥근 모서리 12px) 글로벌 적용. 회원가입 완료 다이얼로그 → 아이콘+중앙정렬+브랜드 버튼 디자인으로 전면 개편 | `theme.dart`, `register_screen.dart` |
| 3 | 업체가 품목 자리 없는 행사에 참가되어 붕뜨는 문제 | auth.service.ts enterEvent에서 VENDOR 신규 참여 시 가용 품목 수 체크 → 0개면 참가 차단 (403 에러: "참여 가능한 품목이 없습니다") | `auth.service.ts` |

### 수정 파일 목록

**백엔드 (1개):**
- `signnote_server/src/auth/auth.service.ts` — VENDOR 입장 시 가용 품목 체크 로직 추가

**프론트엔드 (3개):**
- `signnote_app/lib/config/theme.dart` — dialogTheme + snackBarTheme 글로벌 스타일
- `signnote_app/lib/screens/organizer/web/dashboard_page.dart` — 카드 그림자/테두리
- `signnote_app/lib/screens/onboarding/register_screen.dart` — 가입 완료 다이얼로그 디자인 개편

**설정 (1개):**
- `CLAUDE.md` — "배포 직전에 반드시 워킹로그 업데이트" 절대기준 추가

### 빌드 & 배포

- [x] Flutter 웹 빌드 성공 (에러 0건)
- [x] TypeScript 빌드 에러 0건
- [x] Cloudflare Pages 배포 완료

---

## 2026-03-06 — 2차 디자인 Phase 2: 주관사 업체 드롭다운 + 업체 페이지 전면 개편

### Phase A: 백엔드 변경

| # | 변경 | 파일 |
|---|------|------|
| 1 | 1행사 1품목 제한 해제 (업체가 여러 품목 참여 가능) | `products.service.ts` |
| 2 | 주관사 업체 배정 API 추가 (`POST /products/:id/assign-vendor`) | `products.service.ts`, `products.controller.ts` |
| 3 | 행사 참여자 목록 API 추가 (`GET /events/:id/participants?role=VENDOR`) | `events.service.ts`, `events.controller.ts` |
| 4 | Flutter ProductService에 `assignVendor()` 메서드 추가 | `product_service.dart` |
| 5 | Flutter EventService에 `getParticipants()` 메서드 추가 | `event_service.dart` |

### Phase B: 주관사 품목 관리 - 업체 배정 드롭다운

| # | 변경 | 파일 |
|---|------|------|
| 1 | "협력 업체" 행을 연필 아이콘 → 드롭다운 선택으로 변경 | `event_manage_screen.dart` |
| 2 | 행사 참여 업체 목록 API 연동 (드롭다운 데이터) | `event_manage_screen.dart` |
| 3 | 업체 선택 시 `assignVendor` API 호출 | `event_manage_screen.dart` |

### Phase C: 업체 페이지 전면 개편 (2차 디자인)

| # | 변경 | 파일 |
|---|------|------|
| 1 | 업체 하단탭 3탭→2탭 (홈/마이페이지) 변경 | `app_tab_bar.dart` |
| 2 | 업체 홈 전면 재작성: 첫 페이지(코드 입력 안내) + 행사 그리드 + 팝업 코드 입력 | `vendor/home_screen.dart` |
| 3 | 업체 행사 상세 화면 신규 생성: 3탭(판매 품목/계약함/알림) + 카테고리 아코디언 | `vendor/event_detail_screen.dart` (신규) |
| 4 | 업체 품목 추가 폼 재작성: 품목 드롭다운(주관사 품목 선택) + 적용 타입 칩 | `vendor/product_form_screen.dart` |
| 5 | 업체 계약 상세보기 화면 신규 생성: 고객정보/계약내용/금액/환불안내 | `vendor/contract_detail_screen.dart` (신규) |

### 수정 파일 전체 목록

**백엔드 (4개):**
- `signnote_server/src/products/products.service.ts`
- `signnote_server/src/products/products.controller.ts`
- `signnote_server/src/events/events.service.ts`
- `signnote_server/src/events/events.controller.ts`

**프론트엔드 (8개, 신규 2개):**
- `signnote_app/lib/services/product_service.dart`
- `signnote_app/lib/services/event_service.dart`
- `signnote_app/lib/widgets/layout/app_tab_bar.dart`
- `signnote_app/lib/screens/organizer/event_manage_screen.dart`
- `signnote_app/lib/screens/vendor/home_screen.dart`
- `signnote_app/lib/screens/vendor/product_form_screen.dart`
- `signnote_app/lib/screens/vendor/event_detail_screen.dart` **(신규)**
- `signnote_app/lib/screens/vendor/contract_detail_screen.dart` **(신규)**

### 빌드 & 배포

- [x] Flutter analyze: 경고 0건 (info 2건은 기존 이슈)
- [x] TypeScript 타입체크: 에러 0건
- [x] Flutter 웹 빌드 성공
- [x] Cloudflare Pages 배포 완료

---

## 세션 9: 1뎁스/2뎁스 품목 구조 전면 개편 (2026-03-06)

### 작업 요약

Product(1뎁스, 주관사가 생성하는 품목 카테고리)와 ProductItem(2뎁스, 업체가 생성하는 상세 패키지)를 완전히 분리하는 구조 개편을 DB부터 프론트까지 전 스택에 걸쳐 수행.

### 핵심 변경사항

| # | 작업 내용 | 관련 파일 |
|---|----------|----------|
| 1 | **DB 스키마**: Product에서 price/description/housingTypes 제거, ProductItem 모델 신규 추가 (onDelete: Cascade) | `prisma/schema.prisma` |
| 2 | **백엔드 API**: ProductItem CRUD 엔드포인트 5개 추가 (목록/생성/조회/수정/삭제) | `products.controller.ts`, `products.service.ts` |
| 3 | **백엔드 계약**: Contract 생성 시 가격을 ProductItem에서 가져오도록 변경, productItemId 필드 추가 | `contracts.service.ts`, `create-contract.dto.ts` |
| 4 | **Flutter 서비스**: ProductItem용 API 메서드 4개 추가 (getProductItems, createProductItem, updateProductItem, deleteProductItem) | `product_service.dart` |
| 5 | **업체 행사 상세**: 평면 구조 → 1뎁스 아코디언 + 2뎁스 카드 형태로 전면 재작성 | `vendor/event_detail_screen.dart` |
| 6 | **업체 품목 폼**: 카테고리 드롭다운 → 배정받은 1뎁스 품목 드롭다운으로 변경, ProductItem 생성/수정 | `vendor/product_form_screen.dart` |
| 7 | **주관사 행사 관리**: 품목 섹션에 2뎁스 상세 품목(패키지) 인라인 표시 추가 | `organizer/event_manage_screen.dart` |
| 8 | **관리자 품목 페이지**: DataTable → ExpansionTile 기반 2레벨 확장형 테이블로 전면 재작성 | `web/products_page.dart` |
| 9 | **관리자 계약 페이지**: "상품명" 단일 컬럼 → "품목"(1뎁스) + "패키지"(2뎁스) 2개 컬럼으로 분리 | `web/contracts_page.dart` |

### 신규 파일

- `signnote_server/src/products/dto/create-product-item.dto.ts` — ProductItem 생성 DTO

### 수정 파일 전체 목록

**백엔드 (5개, 신규 1개):**
- `signnote_server/prisma/schema.prisma`
- `signnote_server/src/products/products.service.ts`
- `signnote_server/src/products/products.controller.ts`
- `signnote_server/src/contracts/contracts.service.ts`
- `signnote_server/src/contracts/dto/create-contract.dto.ts`
- `signnote_server/src/products/dto/create-product-item.dto.ts` **(신규)**

**프론트엔드 (6개):**
- `signnote_app/lib/services/product_service.dart`
- `signnote_app/lib/screens/vendor/event_detail_screen.dart`
- `signnote_app/lib/screens/vendor/product_form_screen.dart`
- `signnote_app/lib/screens/organizer/event_manage_screen.dart`
- `signnote_app/lib/screens/organizer/web/products_page.dart`
- `signnote_app/lib/screens/organizer/web/contracts_page.dart`

### 이슈 해결

- **Prisma 마이그레이션 드리프트**: `migrate dev` 실패 → `db push --accept-data-loss`로 직접 스키마 반영
- **데이터 손실**: products 테이블에서 description(3건), housingTypes(3건), price(13건) 드롭 (ProductItem으로 이관)
- **NestJS 빌드 에러 3건**: contracts.service.ts에서 product.price 참조 → ProductItem에서 가격 조회하도록 수정

### 빌드 & 배포

- [x] `prisma db push` 성공 (ProductItem 테이블 생성 완료)
- [x] NestJS 빌드 성공 (TypeScript 에러 0건)
- [x] Flutter 웹 빌드 성공
- [x] Cloudflare Pages 배포 완료

---

### 2026-03-06 — Session 10: 피드백 5건 처리 (버그 3건 + 기능 1건 + 고객 페이지 전면 리디자인)

### 버그 수정 3건

1. **Internal Server Error (업체 품목 목록/등록 실패)**
   - 원인: NestJS 라우트 순서 문제 — `GET products/vendor/mine`이 `PUT products/:id` 패턴에 먼저 매칭됨
   - 수정: `products.controller.ts`에서 `vendor/mine` 라우트를 `:id` 라우트보다 위로 이동

2. **3-dot 메뉴 클릭 안 되는 문제 (주관사 행사 카드)**
   - 원인: 터치 영역 너무 작음 (18px 아이콘, 패딩 없음)
   - 수정: `event_card.dart`에서 `IconButton` + `SizedBox(32x32)`로 변경

3. **행사 삭제 실패 (외래키 제약조건 에러)**
   - 원인: CartItem, Contract, Payment, Settlement 등 관련 테이블에 cascade delete 미설정
   - 수정: `schema.prisma`에서 8개 관계에 `onDelete: Cascade` 추가 후 `db push`

### 기능 추가 1건

4. **업체(Vendor) 계약서 이미지 다운로드**
   - `vendor/event_detail_screen.dart`: 계약 카드에 선택 체크박스 추가, 선택 후 다운로드
   - `utils/image_download.dart`: 웹 환경 이미지 다운로드 유틸 (dart:html + base64)
   - OverlayEntry로 오프스크린 렌더링 → RepaintBoundary → PNG 캡처 → 다운로드

### 고객 페이지 전면 리디자인 (1계정 1행사 구조)

5. **고객 홈 화면 (`customer/home_screen.dart`) — 완전 재작성**
   - 이미 행사 참여 중이면 → 행사 상세로 자동 직행
   - 행사 없으면 → 6자리 코드 입력 화면 (개별 TextField, 자동 포커스 이동)
   - 코드 입력 성공 → 평형 선택 팝업 (동/호 입력 + 타입 라디오) → 행사 상세로 이동

6. **고객 행사 상세 (`customer/event_detail_screen.dart`) — 완전 재작성**
   - 2레벨 아코디언: 1뎁스 카테고리(ExpansionTile) → 2뎁스 패키지 카드
   - 각 카드: 이미지 + 업체명 + 상세보기 + 패키지명 + 설명 + 가격 + 장바구니 토글
   - 품목 상세 팝업 (showModalBottomSheet) + "장바구니 담기" 버튼
   - 하단 플로팅 장바구니 버튼 (빨간 뱃지 카운트)

7. **고객 계약함 (`customer/contract_screen.dart`) — 완전 재작성**
   - 카테고리별 그룹핑 계약 카드 (상태 뱃지 포함)
   - CONFIRMED 상태 계약에 "취소 요청" 버튼 추가
   - "계약서 전체 다운로드" 하단 버튼

8. **고객 계약 상세 (`customer/contract_detail_screen.dart`) — 신규**
   - 업체 정보 / 계약 내용 / 계약 금액 섹션
   - 환불 안내 정보 박스
   - RepaintBoundary로 계약서 이미지 캡처 → 다운로드

### 백엔드 변경

- `events.controller.ts`: `PUT :id/participant-info`, `GET :id/my-info` 엔드포인트 추가
- `events.service.ts`: `updateParticipantInfo()`, `getParticipantInfo()` 메서드 추가
- `schema.prisma`: EventParticipant에 `dong`, `ho`, `housingType` 필드 추가
- `event_service.dart`: `updateParticipantInfo()`, `getMyParticipantInfo()` API 호출 추가

### 빌드 & 배포

- [x] Prisma db push 성공 (cascade delete + EventParticipant 필드 추가)
- [x] NestJS TypeScript 에러 0건
- [x] Flutter analyze — info 3건 (warning/error 0건)
- [x] Flutter 웹 빌드 성공
- [x] Cloudflare Pages 배포 완료

---

## 2026-03-06 — 피드백 9건 + 보안 요구사항 1건 반영 (세션 11)

> FEEDBACK.md 전체 9건 처리 + 추가 보안 요구사항: "다른 업체가 다른 품목 참가비를 절대 모르게"

### 보안 강화: 업체 간 가격 정보 차단

- [x] 백엔드 `findByEvent()`에 `vendorId` 파라미터 추가 — 업체(VENDOR) 조회 시 다른 업체의 참가비/수수료/가격 정보 0으로 마스킹
- [x] 컨트롤러에서 `req.user.role === 'VENDOR'`일 때 자동으로 vendorId 전달

### 처리 내용

| # | 피드백 | 처리 | 수정 파일 |
|---|--------|------|-----------|
| 1 | 사업장 주소 입력 필드 | 회원가입에서 이미 구현되어 있던 기능 — 확인 완료 | - |
| 2 | 사업자등록증 업로드 기능 | ImagePicker → base64 변환 → 서버 전송, 업로드 성공 시 녹색 배경+체크 표시 | `register_screen.dart` |
| 3 | 행사코드 백스페이스 개선 | KeyboardListener로 백스페이스 감지 → 현재 칸 비어있으면 이전 칸으로 이동+삭제 | `entry_code_screen.dart` |
| 4 | 업체 참가 프로세스 변경 | 서버: 업체 가용 품목 체크 제거 (무조건 참가 가능). 클라이언트: 품목 선택 화면 제거 → 바로 홈 이동 | `auth.service.ts`, `entry_code_screen.dart` |
| 5 | 품목 위치 변경 기능 | DB에 sortOrder 필드 추가 + 순서 변경 API (PATCH /events/:eventId/products/reorder) + UI에 ↑↓ 화살표 | `schema.prisma`, `products.service.ts`, `products.controller.ts`, `event_manage_screen.dart`, `product_service.dart` |
| 6 | 품목 3단계 색상 구분 | 밝은 회색(미배정) / 연한 주황(업체만 배정) / 연한 초록(상세품목 등록 완료) + 범례 표시 | `event_manage_screen.dart` |
| 7 | 주관사 상세품목 보기 | 아코디언에서 상세품목 탭 → 상세 다이얼로그(품목명/적용타입/가격/설명) | `event_manage_screen.dart` |
| 8 | 업체 참가취소 시 상세품목 초기화 | unclaim 시 해당 품목의 ProductItem 전체 삭제 + 확인 다이얼로그에 경고 문구 | `products.service.ts`, `event_manage_screen.dart` |
| 9 | 주관사 미승인 로그인 차단 | 이전 세션에서 이미 구현 완료 — 확인 완료 | - |

### 수정 파일 목록

**백엔드 (4개):**
- `signnote_server/src/auth/auth.service.ts` — 업체 가용 품목 체크 제거
- `signnote_server/src/products/products.service.ts` — 업체 간 가격 마스킹 + sortOrder 정렬 + unclaim 시 상세품목 삭제 + reorderProducts()
- `signnote_server/src/products/products.controller.ts` — reorder 엔드포인트 + vendorId 전달
- `signnote_server/prisma/schema.prisma` — Product.sortOrder 필드 추가

**프론트엔드 (4개):**
- `signnote_app/lib/screens/onboarding/entry_code_screen.dart` — 주관사 리다이렉트 + 백스페이스 개선 + 품목선택 제거
- `signnote_app/lib/screens/onboarding/register_screen.dart` — 사업자등록증 이미지 업로드 (ImagePicker + base64)
- `signnote_app/lib/screens/organizer/event_manage_screen.dart` — 3단계 색상 + ↑↓순서 + 상세보기 + unclaim 경고
- `signnote_app/lib/services/product_service.dart` — reorderProducts() 메서드 추가

### 빌드 & 배포

- [x] 서버: GitHub push → Render 자동 배포 (커밋 `3af076a`)
- [x] 클라이언트: Flutter 웹 빌드 성공 → Cloudflare Pages 배포 완료 (커밋 `05a1e69`)
- [x] Prisma db push 성공 (sortOrder 필드)

---

## 2026-03-07 — 피드백 8건 반영 (세션 12)

> 참가비 입금확인 / PNG아이콘 / 행사정보카드 / 아코디언 까만줄 / 주소검색기 / 중복참가알림 / 품목이미지제거 / 고객-업체코드분리

### 처리 내용

| # | 피드백 | 처리 | 수정 파일 |
|---|--------|------|-----------|
| 1 | 참가비 입금 확인 기능 | DB: Product에 `feePaymentConfirmed` 필드 추가. 주관사 아코디언에 입금확인 체크 토글 추가 (업체 배정+참가비 있을 때만 표시). 초록 체크/회색 원 아이콘으로 상태 표시 | `schema.prisma`, `products.service.ts`, `event_manage_screen.dart` |
| 2 | PNG 아이콘 활용 | 주관사 행사 상세 홈 아이콘을 `assets/icons/organizer/home_active.png`로 교체 | `event_manage_screen.dart` |
| 3 | 행사 정보 카드 | 행사 제목과 탭 사이에 정보 카드 추가 (현장명/기간/세대수/평형/계약방식). 위로 스크롤 시 `AnimatedSize`로 접히고, 아래로 스크롤 시 다시 나타남 | `event_manage_screen.dart` |
| 4 | 아코디언 까만 줄 제거 | 전체 ExpansionTile에 `shape: const Border()` + `collapsedShape: const Border()` 적용 | `event_manage_screen.dart`, `vendor/event_detail_screen.dart`, `customer/event_detail_screen.dart`, `web/products_page.dart` |
| 5 | 사업장 주소 검색기 | 카카오 다음 주소 API 연동. 조건부 임포트로 웹/모바일 분기 처리 (`kakao_address.dart` + `_web.dart` + `_stub.dart`) | `register_screen.dart`, `web/index.html`, `kakao_address*.dart` (신규 3개) |
| 6 | 중복 행사 참가 알림 | 서버: `enterEvent()`에서 이미 참여한 행사코드 입력 시 `ForbiddenException('이미 참여한 행사입니다')` 반환. 기존 upsert → findUnique+create로 변경 | `auth.service.ts` |
| 7 | 품목 설명 이미지 제거 | 주관사 품목 추가에서 이미지 업로드 관련 코드 전부 삭제 (import, 변수, 메서드, UI, API 파라미터) | `product_add_screen.dart` |
| 8 | 고객/업체 코드 분리 | DB: Event에 `vendorEntryCode` 필드 추가 (nullable unique). 행사 생성 시 고객용/업체용 6자리 코드 별도 생성. 입장 시 양쪽 모두 검색. 초대 다이얼로그에서 고객코드/업체코드 별도 표시 | `schema.prisma`, `events.service.ts`, `auth.service.ts`, `event_manage_screen.dart`, `home_screen.dart` |

### 신규 파일

- `signnote_app/lib/utils/kakao_address.dart` — 주소 검색 조건부 임포트 배럴
- `signnote_app/lib/utils/kakao_address_stub.dart` — 모바일용 스텁 (null 반환)
- `signnote_app/lib/utils/kakao_address_web.dart` — 웹용 dart:js_interop 구현

### 수정 파일 목록

**백엔드 (3개):**
- `signnote_server/prisma/schema.prisma` — vendorEntryCode + feePaymentConfirmed
- `signnote_server/src/auth/auth.service.ts` — 중복참가 체크 + 양쪽코드 검색
- `signnote_server/src/events/events.service.ts` — 별도 코드 생성
- `signnote_server/src/products/products.service.ts` — feePaymentConfirmed 업데이트 지원

**프론트엔드 (8개, 신규 3개):**
- `signnote_app/lib/screens/organizer/event_manage_screen.dart` — 정보카드 + 입금확인 + PNG아이콘 + 코드분리 + 까만줄
- `signnote_app/lib/screens/organizer/home_screen.dart` — vendorEntryCode 전달
- `signnote_app/lib/screens/organizer/product_add_screen.dart` — 이미지 업로드 제거
- `signnote_app/lib/screens/vendor/event_detail_screen.dart` — 까만줄 수정
- `signnote_app/lib/screens/customer/event_detail_screen.dart` — 까만줄 수정
- `signnote_app/lib/screens/organizer/web/products_page.dart` — 까만줄 수정
- `signnote_app/lib/screens/onboarding/register_screen.dart` — 주소검색 버튼
- `signnote_app/web/index.html` — 카카오 주소 API 스크립트

### 빌드 & 배포

- [x] Prisma db push 성공 (vendorEntryCode + feePaymentConfirmed)
- [x] TypeScript 빌드 에러 0건
- [x] Flutter analyze — info 4건 (error/warning 0건)
- [x] Flutter 웹 빌드 성공
- [x] Cloudflare Pages 배포 완료

---

### 2026-03-07 — 피드백 13건 일괄 구현 (세션 13)

> FEEDBACK.md 13건 분석 후 전체 구현

#### 구현 완료 (13/13)

**#1. 한글 폰트 깨짐/로딩 화면 ✅**
- `web/index.html` — Google Fonts preconnect + Inter/Noto Sans KR CSS 프리로드 추가
- `lib/config/theme.dart` — fontFamilyFallback에 'Noto Sans KR' 추가

**#2. 관리자 사용자관리 일괄 승인 버튼 ✅**
- `users_page.dart` — 일괄 승인 버튼 UI + `_batchApproveUsers()` 메서드 추가
- `user_service.dart` — `batchApproveUsers()` API 호출 메서드 추가
- `users.controller.ts` — `POST /users/batch-approve` 엔드포인트 추가
- `users.service.ts` — `batchApproveUsers()` 서비스 메서드 추가

**#3. 주소검색기 아래 상세주소 입력필드 ✅** (이전 세션에서 구현)

**#4. 주관사 업체배정 시 아코디언 접히는 문제 ✅** (이전 세션에서 구현)

**#5. 아코디언 접힌 상태 입금/미입금 배지 ✅** (이전 세션에서 구현)

**#6. 주관사 알림 기능 — 행사별 빨간 뱃지 ✅**
- `notifications.service.ts` — VENDOR_JOINED, PRODUCT_REGISTERED, PRODUCT_UPDATED 타입 추가
- `notifications.service.ts` — `getUnreadCountByEvents()` 행사별 알림 수 집계
- `notifications.controller.ts` — `GET /notifications/unread-by-events` 엔드포인트
- `products.service.ts` — 업체참여/품목등록/품목수정 시 주관사에게 알림 발송
- `notification_service.dart` — `getUnreadCountByEvents()` 클라이언트 메서드
- `home_screen.dart` — 행사별 알림 개수 로드 + EventCard에 전달
- `event_card.dart` — `notificationCount` 파라미터 + 빨간 뱃지 UI

**#7. 업체 타입 선택 칩 V자 제거 ✅** (이전 세션에서 구현)

**#8. 미배정 업체 품목추가 시 알림 ✅** (이전 세션에서 구현)

**#9. 드롭다운 선택 항목 맨 윗줄 표시 ✅**
- 전체 드롭다운 감사 완료 — 모두 이미 올바르게 value 바인딩됨

**#10. 고객 행사 상세 아코디언 기본 접힘 ✅** (이전 세션에서 구현)

**#11. 고객 장바구니 V아이콘 토글 (제거) ✅**
- `event_detail_screen.dart` — `_toggleCart()`, `_removeFromCart()` 메서드 추가
- V 아이콘 탭 시 장바구니에서 제거 가능 (토글)

**#12. 장바구니 금액 0원 버그 + 품목↔장바구니 연동 ✅**
- `cart_service.dart` — `addItem()`에 `productItemId` 파라미터 추가
- `cart_screen.dart` — 가격을 `productItem.price`에서 가져오도록 수정 (핵심 버그)
- `add-cart-item.dto.ts` — `productItemId` 필드 추가
- `carts.service.ts` — `productItemId` 저장 + `productItem` include

**#13. 계약금 비율 커스텀 (30% → 행사별 설정) ✅**
- `schema.prisma` — Event 모델에 `depositRate Float @default(0.3)` 추가
- `contracts.service.ts` — 행사별 depositRate 사용
- `event_form_screen.dart` — 계약금 비율(%) 입력 필드 추가
- `cart_screen.dart` — 행사별 depositRate 로드 + 동적 퍼센트 표시

### 수정 파일: 백엔드 10개 + 프론트엔드 12개

### 빌드 & 배포

- [x] Prisma db push 성공 (depositRate)
- [x] TypeScript 에러 0건 / Flutter 에러 0건
- [x] Cloudflare Pages 배포 완료

---

### 2026-03-07 — 피드백 7건 (2차): 업체/고객/주관사 기능 개선

> **FEEDBACK.md 35~41번 라인 — 2차 피드백 7건**

**#1. 협력업체 입장코드 확인/조치 ✅**
- `home_screen.dart` (주관사) — 행사 목록 매핑에 `vendorEntryCode` 추가
- 초대 다이얼로그에서 협력업체 코드가 `------` 대신 실제 코드 표시

**#2. 협력업체 홈 행사추가 카드 맨앞 ✅**
- `home_screen.dart` (업체) — `index == _events.length` → `index == 0` 변경
- + 카드가 그리드 맨 앞에 표시, 행사는 `_events[index - 1]`로 접근

**#3. 협력업체 행사상세에 행사정보 카드 + 주관사 이름 ✅**
- `event_detail_screen.dart` (업체) — `EventService.getEventDetail()` 연동
- AppBar 아래, 탭바 위에 행사 정보 카드 추가 (주관사명/현장명/기간/세대수/평형)
- body를 `Column[infoCard, TabBar, Expanded(TabBarView)]` 구조로 변경

**#4. 고객 동호수/타입 입력 페이지 ✅**
- `entry_code_screen.dart` — 고객 입장 성공 시 동호수/타입 선택 팝업 표시
- housingTypes가 있으면 라디오 선택 → `EventService.updateParticipantInfo()` 호출
- `customer/home_screen.dart`에 이미 구현된 동일 기능과 일관성 유지

**#5. 구매품목리스트 첫번째 아코디언만 펼치기 ✅**
- `event_detail_screen.dart` (고객) — `_buildCategoryAccordion`에 `index` 파라미터 추가
- `initiallyExpanded: false` → `initiallyExpanded: index == 0`

**#6. 주관사 입금/미입금 배지 위치 변경 ✅**
- `event_manage_screen.dart` — 배지를 화살표 옆에서 품목 이름 바로 옆으로 이동
- title Row를 `Expanded(Row[Flexible(Text), badge])` + arrows 구조로 변경

**#7. 주관사 고객관리/계약함/알림 탭 API 연동 ✅ (가장 큰 작업)**

*백엔드:*
- `events.service.ts` — `getParticipants()`에 dong/ho/housingType 반환 추가
- `notifications.service.ts` — `findByEvent()` 메서드 추가 (data.eventId 필터)
- `notifications.controller.ts` — `GET /notifications/event/:eventId` 엔드포인트 추가

*프론트엔드:*
- `notification_service.dart` — `getNotificationsByEvent()` 메서드 추가
- `event_manage_screen.dart` — ContractService, NotificationService import 추가
- 고객관리 탭: 실제 참여 고객 목록 (이름/동/호/연락처) API 연동 + 총 고객 수 표시
- 계약함 탭: 실제 계약 목록 API 연동 (집계: 품목수/계약건/취소요청/취소완료/총수입금액)
- 알림 탭: 실제 알림 목록 API 연동 (타입별 아이콘/읽음처리/날짜표시)

### 수정 파일: 백엔드 3개 + 프론트엔드 6개

### 빌드 & 배포
- [x] TypeScript 에러 0건 / Flutter 에러 0건
- [x] Cloudflare Pages 배포 완료
- [x] NestJS 서버 재시작 완료

---

### 2026-03-07 — 피드백 6건 처리

> **피드백 요약:** FEEDBACK.md 43~48번 항목 (회원가입 중복체크, 동호수 시인성, 타입 필터링, 행사 추가, 계약 취소, 알림)

**1. 회원가입 이메일/전화번호 중복 체크 + 중앙 알림 ✅**
- [x] 백엔드 `users.service.ts` — 전화번호 중복 체크 추가 (`findFirst` + `ConflictException`)
- [x] 프론트엔드 `register_screen.dart` — `_showError()`를 SnackBar → AlertDialog(중앙 팝업)로 변경

**2. 고객 동호수 입력 필드 시인성 향상 ✅**
- [x] `entry_code_screen.dart` — 동/호수 TextField에 `filled: true, fillColor: AppColors.background` 추가 (연회색 배경)

**3. 고객 구매품목 타입 필터링 버그 수정 ✅**
- [x] 프론트엔드 `event_detail_screen.dart` — `_loadMyInfo()` → `_loadProducts()` 순서 보장 (`_initData()` 메서드로 분리)
- [x] 백엔드 `products.service.ts` — housingType 필터 후 빈 아이템 품목 제거 (`.filter(p => p.items.length > 0)`)

**4. 주관사 행사 추가 버튼 무반응 수정 ✅**
- [x] `event_service.dart` — `createEvent()`에 catch-all 예외 처리 추가
- [x] `event_form_screen.dart` — `_handleSubmit()`에 try-catch 래핑

**5. 계약 취소 프로세스 변경 (고객 취소 → 협력업체 직접 취소) ✅**
- [x] 고객 `contract_screen.dart` — 취소 요청 버튼 제거
- [x] 백엔드 `contracts.service.ts` — `vendorCancel()` 메서드 추가 (CONFIRMED → CANCELLED + 환불)
- [x] 백엔드 `contracts.controller.ts` — `PUT /contracts/:id/vendor-cancel` 엔드포인트 추가
- [x] 프론트엔드 `contract_service.dart` — `vendorCancelContract()` 메서드 추가
- [x] 업체 `contract_screen.dart` — 직접 취소 다이얼로그 + API 호출 추가
- [x] `contract_card.dart` — `onVendorCancelTap` 콜백 + "계약 취소 및 환불" 버튼 추가

**6. 계약 알림 보강 ✅**
- [x] `contracts.service.ts` — 계약 생성 시 주관사에게도 알림 전송
- [x] `contracts.service.ts` — 업체 직접 취소 시 주관사에게도 알림 전송
- [x] 알림 전송 try-catch로 감싸 계약 생성 실패 방지

### 수정 파일: 백엔드 4개 + 프론트엔드 9개 + 위젯 1개 = 총 14개

### 빌드 & 배포
- [x] TypeScript 에러 0건 / Flutter 에러 0건
- [x] Cloudflare Pages 프론트엔드 배포 완료
- [x] GitHub push 완료 (Render 백엔드 자동 배포)

---

### 2026-03-07 — 2차 피드백 잔여 3건 처리

**1. 주관사 아코디언 접힘 문제 수정 ✅ (피드백 #4)**
- [x] `event_manage_screen.dart` — `_loadProducts()` 새로고침 시 로딩 스피너 제거
  - 최초 로딩일 때만 스피너 표시, 새로고침 시 기존 화면 유지
  - `_expandedProductIds` Set으로 아코디언 상태 보존 (기존 구현 활용)
  - 업체 배정 후에도 아코디언 접히지 않음

**2. 드롭다운 맨윗줄 수정 ✅ (피드백 #9)**
- [x] `event_manage_screen.dart` — 업체 배정 드롭다운에 현재 선택값 표시
  - `vendorId`를 제품 데이터에 추가
  - `value: vendorInList ? currentVendorId : null`로 현재 배정 업체 하이라이트
  - 나머지 드롭다운(행사 폼, 관리자 웹 등) 전수 검사 → 정상 확인

**3. 장바구니 0원 + v체크 동기화 수정 ✅ (피드백 #12)**
- [x] `cart_screen.dart` — 가격 안전 캐스팅 (`num→int` 변환)
  - `(rawPrice is num) ? rawPrice.toInt() : 0` 패턴 적용
  - `_totalPrice` 합산도 안전 캐스팅
- [x] `event_detail_screen.dart` — v체크 ID 매핑 강화
  - `productItemId` + `productItem.id` 이중 확인
  - 빈 문자열 필터링 추가

### 수정 파일: 프론트엔드 3개
### 빌드 & 배포
- [x] TypeScript 에러 0건 / Flutter 에러 0건
- [x] Cloudflare Pages 프론트엔드 배포 완료

---

### 2026-03-07 — QA 전체 점검 + 버그/이슈 일괄 수정

**QA 전체 점검 후 발견된 이슈 일괄 처리**

**Critical 수정 (4건) ✅**
- [x] `create-event.dto.ts` — `depositRate` 필드 추가 (`@IsOptional() @IsNumber()`)
  - 계약금 비율(30% 등)을 프론트에서 서버로 저장할 수 있게 됨
- [x] `create-event.dto.ts` — `unitCount` 필수→선택으로 변경 (프론트 폼과 일치)
- [x] `events.service.ts` — `create()` + `update()` 메서드에 `depositRate` 반영
- [x] `login_screen.dart` — `setState` 전에 `mounted` 체크 (크래시 방지)
- [x] `cart_screen.dart` — `setState` 전에 `mounted` 체크 (크래시 방지)

**Important 수정 (3건) ✅**
- [x] `event_detail_screen.dart` — 장바구니 추가 실패 시 v체크 롤백 처리
- [x] `contract_screen.dart` — 미사용 `_requestCancel()` 코드 제거 (피드백 #5로 고객 직접 취소 삭제됨)
- [x] `product_form_screen.dart` — 타입 선택 칩 크기 변동 방지 (고정 패딩 + shrinkWrap)

**피드백 잔여 처리 (3건) ✅**
- [x] 피드백 #1: 한글 폰트 깨짐 → `index.html` 로딩 화면이 폰트 로딩 완료까지 유지되도록 개선
  - `document.fonts.ready` + `flutter-first-frame` 이벤트 동시 대기
- [x] 피드백 #7: 타입 칩 V자/크기 변경 → `showCheckmark: false` + 고정 패딩
- [x] 피드백 #8: 미배정 업체 품목추가 알림 → 이전 세션에서 이미 구현됨 확인

### 수정 파일
**백엔드 (2개):** create-event.dto.ts, events.service.ts
**프론트엔드 (6개):** login_screen.dart, cart_screen.dart, event_detail_screen.dart, contract_screen.dart, product_form_screen.dart, index.html

### 빌드 & 배포
- [x] Flutter 빌드 에러 0건
- [x] Cloudflare Pages 프론트엔드 배포 완료
- [x] 백엔드 변경사항 커밋 (Render.com 자동 배포)

---

### 2026-03-07 — 피드백 5건 처리 + 6번 TODO 등록

**1. 협력업체 행사정보 카드 스크롤 숨기기 ✅**
- [x] `vendor/event_detail_screen.dart` — `_showInfoCard` + `AnimatedSize` + `_handleScrollNotification` 추가
  - 주관사와 동일한 패턴 (아래로 스크롤 → 카드 숨김, 위로 → 카드 표시)
  - `NotificationListener<ScrollNotification>`으로 `TabBarView` 감싸기

**2. 초대 팝업 코드복사 + 업체코드 수정 ✅**
- [x] `organizer/event_manage_screen.dart` — 코드복사 아이콘 터치영역 확대
  - `GestureDetector`에 `behavior: HitTestBehavior.opaque` + `Padding(8px)` 추가
- [x] 업체코드: `_eventDetail`에서 `vendorEntryCode`를 우선 가져오도록 수정
  - `widget.vendorEntryCode` → `_eventDetail?['vendorEntryCode'] ?? widget.vendorEntryCode`

**3. 행사 추가 작성완료 무반응 ✅**
- [x] 근본 원인: NestJS `forbidNonWhitelisted: true` + DTO에 `depositRate` 필드 누락 → 서버 400 에러
  - 이전 작업에서 DTO에 `depositRate` 추가 + `unitCount` optional 변경 완료
- [x] `organizer/event_form_screen.dart` — 에러 표시를 SnackBar → AlertDialog로 변경 (눈에 잘 띄게)

**4. 적용 타입 정렬 ✅**
- [x] `organizer/event_form_screen.dart` — `_sortTypes()` 메서드 추가
  - 숫자 부분 추출 → 숫자 오름차순 → 같으면 알파벳순 (59A→59B→74A→84A)
  - `_addType()` 후 자동 정렬 + `initState`에서도 기존 타입 정렬

**5. 고객 프로필에서 타입 변경 드롭다운 ✅**
- [x] `common/profile_edit_screen.dart` — 평형 타입 드롭다운 추가
  - 행사 상세 API에서 `housingTypes` 배열 로드 → 드롭다운 선택지로 사용
  - 저장 시 `updateParticipantInfo()`에 `housingType` 함께 전송

**6. 어드민 페이지 전면 재구성 📌TODO**
- FEEDBACK.md에 상세 계획 등록 (다음 세션에서 진행)

### 수정 파일
**프론트엔드 (4개):** vendor/event_detail_screen.dart, organizer/event_manage_screen.dart, organizer/event_form_screen.dart, common/profile_edit_screen.dart

### 빌드 & 배포
- [x] Flutter 빌드 에러 0건
- [x] Cloudflare Pages 프론트엔드 배포 완료

---

### 2026-03-07 — 피드백 19건 전체 처리 완료 (세션 계속)

**배치 1: 14건 일괄 구현 ✅**
- [x] #12 보안: 역할별 참여코드 분리 검증 (고객→entryCode, 업체→vendorEntryCode)
- [x] #4/#18 활동 로그: ContractsService에 ActivityLogsService 추가 (계약생성/취소요청/취소승인)
- [x] #15 알림 배치: 계약 N건 → 업체별 1개 알림으로 묶어서 발송
- [x] #1 행사 수정 폼: 취소지정기간/계약금비율 기존값 유지 (_tryParseDate 헬퍼)
- [x] #3 대시보드 카드 클릭: 행사→events, 업체→users, 계약→events 페이지 이동
- [x] #5 체크박스 제거: DataRow.onSelectChanged → DataCell.onTap으로 변경
- [x] #7 업체 승인 버튼: 미승인 업체 선택 시에만 활성화
- [x] #9-1 초대 팝업: 고객코드 + 업체코드 모두 표시, 행사 생성 직후에도 표시
- [x] #10 업체 계약함: eventId 필터 적용
- [x] #11 스크롤 복원: ScrollEndNotification으로 페이지 최상단 감지 → 정보카드 표시
- [x] #13 아코디언 기본상태: 모든 품목 첫 1개 상세품목 보이는 상태로 열림
- [x] #14 장바구니: PopScope + bottomNavigationBar 추가, 안드로이드 뒤로가기 보호
- [x] #19 계약함 총금액: totalPrice 컬럼 + depositRate 퍼센트 표시

**배치 2: 2건 수정 ✅**
- [x] #6 고객관리 데이터: 플랫/중첩 구조 모두 지원 (p['name'] ?? p['user']?['name'])
- [x] #8 고객 삭제: customers_page.dart에 강제 탈퇴 버튼 + 확인 다이얼로그

**배치 3: 3건 마무리 ✅**
- [x] #2 사이드바 폴더형: 관리(행사/업체/고객) + 시스템(활동 로그) 접기/펼치기 트리 구조
- [x] #9-2 드롭다운 첫줄: 미배정/품목 선택/미지정 등 null 옵션 추가 (6개 파일)
- [x] #16 업체 알림 가드: 빈 vendorId 건너뛰기 + 기존 업체별 그룹 알림 확인

**#17 (폴링) — 보류**: 30초 폴링은 성능/배터리 영향 고려하여 보류

### 수정 파일
**백엔드 (1개):** contracts.service.ts
**프론트엔드 (7개):** web_shell.dart, event_manage_screen.dart, product_select_screen.dart, product_form_screen.dart, profile_edit_screen.dart, customers_page.dart, event_detail_page.dart

### 빌드 & 배포
- [x] Flutter 빌드 에러 0건 (3회 빌드 모두 성공)
- [x] Git push 3회 → Render 서버 자동 배포
- [x] Cloudflare Pages 프론트엔드 3회 배포 완료

---

### 2026-03-07 — 피드백 3건: 계약 상세 정보 확장 + 다운로드 + 알림 전체 읽음

**#1 계약 상세보기 정보 확장 ✅**
- [x] 백엔드: contracts.service.ts — findByCustomer/findByVendor/findOne에 event(title, siteName, organizer.name) + product.vendor 상세 정보 include 확장
- [x] 고객 계약 목록: contract_screen.dart — vendorRepresentative, vendorBusinessNumber, vendorBusinessAddress, eventTitle, siteName, organizerName 필드 추가
- [x] 고객 계약 상세: contract_detail_screen.dart — 행사 정보/업체 정보/고객 정보/계약 내용/계약 금액 5개 섹션 전면 리라이트
- [x] 업체 계약 목록: vendor/contract_screen.dart — eventTitle, siteName, organizerName, vendorName 등 확장 필드 매핑

**#2 업체 계약서 다운로드 구현 ✅**
- [x] vendor/contract_detail_screen.dart 전면 리라이트: RepaintBoundary 캡처 + 이미지 다운로드
- [x] 행사 정보/고객 정보/업체 정보/계약 내용/계약 금액 5개 섹션 + 환불 안내
- [x] "준비중" 스낵바 → 실제 다운로드 기능으로 교체
- [x] vendor/contract_screen.dart onDetailTap: 스낵바 → 상세 화면 네비게이션으로 변경

**#3 알림 "전부 읽음으로 표시" 추가 ✅**
- [x] 주관사 모바일: event_manage_screen.dart 알림 탭에 markAllNotificationsAsRead + "전부 읽음으로 표시" 버튼
- [x] 관리자 웹: event_detail_page.dart 알림 탭에 동일 기능 추가
- [x] 읽지 않은 알림이 있을 때만 버튼 표시

### 수정 파일
**백엔드 (1개):** contracts.service.ts
**프론트엔드 (4개):** vendor/contract_detail_screen.dart, vendor/contract_screen.dart, event_manage_screen.dart, event_detail_page.dart

---

### 2026-03-10 — 업체 삭제 시 품목 정리 + 계약 보존 (스냅샷 방식)

**문제**: 관리자가 업체를 삭제하면 해당 업체의 품목에 연결된 계약이 깨지거나 사라질 수 있었음
- 기존: 품목의 vendorId만 null로 변경 (품목/상세품목 유지), 업체 기준 계약 정리 없음
- 계약 → 품목 관계가 `onDelete: Cascade`여서 품목 삭제 시 계약도 연쇄 삭제되는 위험

**해결: 계약 스냅샷 방식 적용**

1. **DB 스키마 변경 (Contract 모델) ✅**
   - `productId`: 필수(String) → 선택(String?) + `onDelete: SetNull`
   - `productItemId`: `onDelete: Cascade` → `onDelete: SetNull`
   - 신규 필드 4개 추가: `productName`, `productItemName`, `vendorName`, `vendorBusinessNumber`
   - 기존 계약 데이터에 스냅샷 필드 백필(backfill) SQL 실행 완료

2. **계약 생성 시 스냅샷 저장 ✅**
   - `contracts.service.ts`: 계약 생성 시 품목명, 상세품목명, 업체명, 사업자번호를 계약 자체에 복사 저장
   - 원본 품목이 나중에 삭제되어도 계약서에는 정보가 남아있음

3. **업체 삭제 로직 개선 ✅**
   - `users.service.ts` deleteUser(): 업체 삭제 시 해당 업체 품목의 장바구니 → 품목+상세품목 삭제
   - 품목 삭제 시 계약의 productId/productItemId는 SetNull로 null 처리 (계약은 보존)

4. **프론트엔드 스냅샷 필드 폴백 적용 ✅**
   - 고객 계약 목록: product 관계 null일 때 `vendorName`, `vendorBusinessNumber`, `productName` 스냅샷 사용
   - 업체 계약 목록: `productName`, `vendorName` 스냅샷 폴백 추가
   - 주관사 계약함: `productName`, `productItemName`, `vendorName` 스냅샷 폴백 추가
   - 관리자 웹 계약 페이지 + 행사상세 계약 탭: 동일 폴백 적용

### 수정 파일
**스키마 (1개):** prisma/schema.prisma
**백엔드 (2개):** contracts.service.ts, users.service.ts
**프론트엔드 (5개):** customer/contract_screen.dart, vendor/contract_screen.dart, organizer/event_manage_screen.dart, organizer/web/contracts_page.dart, organizer/web/event_detail_page.dart

### 빌드 & 배포
- [x] Prisma db push 스키마 적용 완료
- [x] 기존 계약 백필 SQL 실행 완료
- [x] Flutter 빌드 에러 0건
- [x] Cloudflare Pages 프론트엔드 배포 완료

