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

<!-- 새 항목은 이 아래에 추가 -->