import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/product_service.dart';
import '../../services/event_service.dart';
import '../../services/contract_service.dart';
import '../../services/notification_service.dart';
import '../../utils/number_formatter.dart';
import '../../utils/csv_download.dart';
import '../customer/contract_detail_screen.dart';
import 'product_add_screen.dart';

// ============================================
// 주관사 행사 상세 화면 (2차 디자인)
//
// 디자인 참고: 4.주관사용-품목 상세.jpg
// 상단: 홈 아이콘 + 행사명 + 사람 아이콘
// 4개 탭: 품목 관리 / 고객관리 / 계약함 / 알림
// ============================================

class OrganizerEventManageScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String? entryCode;
  final String? vendorEntryCode; // 협력업체 전용 참여 코드

  const OrganizerEventManageScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.entryCode,
    this.vendorEntryCode,
  });

  @override
  State<OrganizerEventManageScreen> createState() =>
      _OrganizerEventManageScreenState();
}

class _OrganizerEventManageScreenState
    extends State<OrganizerEventManageScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  // 품목 데이터
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;

  // 행사에 참여한 업체 목록 (드롭다운용)
  List<Map<String, dynamic>> _vendors = [];

  // 행사 상세 정보 (정보 카드용)
  Map<String, dynamic>? _eventDetail;

  // 행사 정보 카드 표시 여부 (기본: 접힌 상태)
  bool _showInfoCard = false;

  // 아코디언 펼침 상태 유지 (리빌드 시에도 유지)
  final Set<String> _expandedProductIds = {};

  // 고객 목록 데이터
  List<Map<String, dynamic>> _customers = [];
  bool _isLoadingCustomers = true;
  final Set<int> _selectedCustomerIndices = {}; // 선택된 고객 인덱스

  // 계약 데이터
  List<Map<String, dynamic>> _contracts = [];
  bool _isLoadingContracts = true;

  // 알림 데이터
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoadingNotifications = true;

  final ProductService _productService = ProductService();
  final EventService _eventService = EventService();
  final ContractService _contractService = ContractService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProducts();
    _loadVendors();
    _loadEventDetail();
    _loadCustomers();
    _loadContracts();
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 서버에서 품목 목록 가져오기 (1뎁스 + 2뎁스 items 포함)
  // 새로고침 시 로딩 스피너 없이 데이터만 교체 (아코디언 상태 유지)
  Future<void> _loadProducts() async {
    // 최초 로딩일 때만 스피너 표시 (새로고침 시에는 기존 화면 유지)
    final isInitialLoad = _products.isEmpty;
    if (isInitialLoad) {
      setState(() { _isLoading = true; _error = null; });
    }

    final result = await _productService.getProductsByEvent(widget.eventId);

    if (!mounted) return;

    if (result['success'] == true) {
      final List products = result['products'] ?? [];
      setState(() {
        _products = products.map<Map<String, dynamic>>((p) {
          // 2뎁스 상세 품목 목록
          final items = (p['items'] as List?)?.map<Map<String, dynamic>>((item) => {
            'id': item['id']?.toString() ?? '',
            'name': item['name'] ?? '',
            'description': item['description'] ?? '',
            'price': item['price'] ?? 0,
            'housingTypes': item['housingTypes'] != null ? List<String>.from(item['housingTypes']) : <String>[],
          }).toList() ?? [];

          return {
            'id': p['id']?.toString() ?? '',
            'category': p['category'] ?? '기타',
            'vendorId': p['vendorId']?.toString() ?? '', // 업체 ID (드롭다운 값 매칭용)
            'vendorName': p['vendorName'] ?? '',
            'name': p['name'] ?? '품목명 없음',
            'imageUrl': p['image'],
            'participationFee': p['participationFee'] ?? 0,
            'commissionRate': p['commissionRate'] ?? 0,
            'feePaymentConfirmed': p['feePaymentConfirmed'] ?? false, // 참가비 입금 확인
            'items': items,
          };
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? '품목 목록을 불러올 수 없습니다';
        _isLoading = false;
      });
    }
  }

  // 행사 상세 정보 가져오기 (정보 카드용)
  Future<void> _loadEventDetail() async {
    final result = await _eventService.getEventDetail(widget.eventId);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _eventDetail = result['event'] as Map<String, dynamic>?;
      });
    }
  }

  // 고객 목록 가져오기 (CUSTOMER 역할 참여자)
  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);

    final result = await _eventService.getParticipants(widget.eventId, role: 'CUSTOMER');
    if (!mounted) return;

    if (result['success'] == true) {
      final List participants = result['participants'] ?? [];
      setState(() {
        _customers = participants.map<Map<String, dynamic>>((p) => {
          'id': p['id']?.toString() ?? '',
          'name': p['name'] ?? '이름 없음',
          'phone': p['phone'] ?? '',
          'dong': p['dong'] ?? '',
          'ho': p['ho'] ?? '',
          'housingType': p['housingType'] ?? '',
        }).toList();
        _isLoadingCustomers = false;
      });
    } else {
      setState(() => _isLoadingCustomers = false);
    }
  }

  // 계약 목록 가져오기 (행사별)
  Future<void> _loadContracts() async {
    setState(() => _isLoadingContracts = true);

    final result = await _contractService.getEventContracts(widget.eventId);
    if (!mounted) return;

    if (result['success'] == true) {
      final List contracts = result['contracts'] ?? [];
      setState(() {
        _contracts = contracts.map<Map<String, dynamic>>((c) => {
          'id': c['id']?.toString() ?? '',
          'customerName': c['customerName'] ?? c['customer']?['name'] ?? '고객',
          'customerPhone': c['customerPhone'] ?? c['customer']?['phone'] ?? '',
          'customerAddress': c['customerAddress'] ?? '',
          'customerDong': c['customerDong'] ?? '',
          'customerHo': c['customerHo'] ?? '',
          'customerHousingType': c['customerHousingType'] ?? '',
          'productName': c['productItem']?['name'] ?? c['product']?['name'] ?? c['productItemName'] ?? c['productName'] ?? '품목',
          'productCategory': c['product']?['category'] ?? c['productName'] ?? '기타',
          'originalPrice': c['originalPrice'] ?? 0,
          'depositAmount': c['depositAmount'] ?? 0,
          'remainAmount': c['remainAmount'] ?? 0,
          'status': c['status'] ?? 'PENDING',
          'createdAt': c['createdAt']?.toString() ?? '',
        }).toList();
        _isLoadingContracts = false;
      });
    } else {
      setState(() => _isLoadingContracts = false);
    }
  }

  // 알림 목록 가져오기 (행사별)
  Future<void> _loadNotifications() async {
    setState(() => _isLoadingNotifications = true);

    final result = await _notificationService.getNotificationsByEvent(widget.eventId);
    if (!mounted) return;

    if (result['success'] == true) {
      final List notifications = result['notifications'] ?? [];
      setState(() {
        _notifications = notifications.map<Map<String, dynamic>>((n) => {
          'id': n['id']?.toString() ?? '',
          'type': n['type'] ?? '',
          'title': n['title'] ?? '',
          'body': n['body'] ?? '',
          'isRead': n['isRead'] ?? false,
          'createdAt': n['createdAt']?.toString() ?? '',
        }).toList();
        _isLoadingNotifications = false;
      });
    } else {
      setState(() => _isLoadingNotifications = false);
    }
  }

  // 행사 정보 카드 수동 접기/펼치기 토글
  void _toggleInfoCard() {
    setState(() => _showInfoCard = !_showInfoCard);
  }

  // 행사에 참여한 업체 목록 가져오기 (드롭다운용)
  Future<void> _loadVendors() async {
    final result = await _eventService.getParticipants(widget.eventId, role: 'VENDOR');
    if (!mounted) return;
    if (result['success'] == true) {
      final List participants = result['participants'] ?? [];
      setState(() {
        _vendors = participants.map<Map<String, dynamic>>((p) => {
          'id': p['id']?.toString() ?? '',
          'name': p['name'] ?? '이름 없음',
          'phone': p['phone']?.toString(),
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      // 상단 바: 홈 아이콘 + 행사명 + 사람 아이콘
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        // 홈 아이콘 (PNG 에셋 사용)
        leading: IconButton(
          icon: Image.asset('assets/icons/organizer/home_active.png', width: 26, height: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _toggleInfoCard,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.eventTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              // 행사정보 접기/펼치기 화살표
              AnimatedRotation(
                turns: _showInfoCard ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down, size: 22, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          // 업체 리스트 아이콘 (우측 슬라이드 패널)
          IconButton(
            icon: const Icon(Icons.groups_outlined, size: 26),
            tooltip: '참여 업체 목록',
            onPressed: () => _showVendorListPanel(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 행사 정보 카드 (수동 접기/펼치기 — 제목 옆 화살표 클릭)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _showInfoCard ? _buildEventInfoCard() : const SizedBox.shrink(),
          ),
          // 4개 탭
          TabBar(
            controller: _tabController,
            labelColor: AppColors.organizer,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.organizer,
            indicatorWeight: 2,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            tabs: const [
              Tab(text: '품목 관리'),
              Tab(text: '고객관리'),
              Tab(text: '계약함'),
              Tab(text: '알림'),
            ],
          ),
          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductTab(),
                _buildCustomerTab(),
                _buildContractTab(),
                _buildNotificationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 행사 정보 카드 (제목과 탭 사이)
  Widget _buildEventInfoCard() {
    if (_eventDetail == null) return const SizedBox.shrink();

    final siteName = _eventDetail!['siteName'] ?? '';
    final unitCount = _eventDetail!['unitCount'] ?? 0;
    final housingTypes = (_eventDetail!['housingTypes'] as List?)?.join(', ') ?? '';
    final startDate = _eventDetail!['startDate']?.toString().substring(0, 10) ?? '';
    final endDate = _eventDetail!['endDate']?.toString().substring(0, 10) ?? '';
    final contractMethod = _eventDetail!['contractMethod'] == 'integrated' ? '통합계약' : '개별계약';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0), // 연한 주황 배경
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (siteName.isNotEmpty) ...[
            _infoRow('현장명', siteName),
            const SizedBox(height: 6),
          ],
          if (startDate.isNotEmpty)
            _infoRow('기  간', '$startDate ~ $endDate'),
          const SizedBox(height: 6),
          if (unitCount > 0)
            _infoRow('세대수', '${NumberFormat('#,###').format(unitCount)} 세대'),
          if (housingTypes.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow('평  형', housingTypes),
          ],
          const SizedBox(height: 6),
          _infoRow('계약방식', contractMethod),
        ],
      ),
    );
  }

  // 정보 카드 행 (라벨 + 값)
  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 탭 1: 품목 관리
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildProductTab() {
    return Column(
      children: [
        // "판매 품목 리스트 >" + "초대" 버튼
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
          child: Row(
            children: [
              const Text('판매 품목 리스트', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
              const Spacer(),
              // 초대 버튼
              _buildInviteButton(),
            ],
          ),
        ),
        // 총 N 품목 + 색상 범례
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Row(
            children: [
              Text(
                '총 ${_products.length} 품목',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              // 색상 범례
              _colorLegend(const Color(0xFFF5F5F5), '미배정'),
              const SizedBox(width: 8),
              _colorLegend(const Color(0xFFFFF3E0), '배정'),
              const SizedBox(width: 8),
              _colorLegend(const Color(0xFFE8F5E9), '등록완료'),
            ],
          ),
        ),
        // 아코디언 품목 목록
        Expanded(child: _buildProductList()),
        // 하단: "품목 추가하기" 주황 버튼
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => OrganizerProductAddScreen(eventId: widget.eventId),
                  ),
                );
                if (result == true) _loadProducts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.organizer,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('품목 추가하기'),
            ),
          ),
        ),
      ],
    );
  }

  // 품목 리스트 (아코디언)
  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.organizer));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadProducts, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('등록된 품목이 없습니다', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // 꾹 눌러서 드래그앤드롭으로 순서 변경 (스마트폰 아이콘 옮기기 방식)
    return ReorderableListView(
      buildDefaultDragHandles: false, // 기본 드래그 핸들 끄기 (커스텀 핸들과 충돌 방지)
      padding: const EdgeInsets.symmetric(horizontal: 16),
      proxyDecorator: (child, index, animation) {
        // 드래그 중인 아이템에 그림자 효과
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        // ReorderableListView는 newIndex가 oldIndex보다 크면 1 더 큰 값을 줌
        if (newIndex > oldIndex) newIndex -= 1;
        _moveProduct(oldIndex, newIndex);
      },
      children: _products.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        return KeyedSubtree(
          key: ValueKey(product['id']),
          child: _buildAccordionItem(product),
        );
      }).toList(),
    );
  }

  // 품목 3단계 색상 결정
  // 1단계: 업체 미배정 → 밝은 회색
  // 2단계: 업체 배정됨, 상세품목 없음 → 연한 주황
  // 3단계: 업체 배정 + 상세품목 등록 완료 → 연한 초록
  Color _getAccordionColor(Map<String, dynamic> product) {
    final vendorName = product['vendorName'] as String? ?? '';
    final items = product['items'] as List? ?? [];
    final hasVendor = vendorName.isNotEmpty;

    if (!hasVendor) return const Color(0xFFF5F5F5); // 밝은 회색 (미배정)
    if (items.isEmpty) return const Color(0xFFFFF3E0); // 연한 주황 (업체만 배정)
    return const Color(0xFFE8F5E9); // 연한 초록 (상세품목 등록 완료)
  }

  // 아코디언 품목 아이템
  Widget _buildAccordionItem(Map<String, dynamic> product) {
    final name = product['name'] ?? '';
    final vendorName = product['vendorName'] as String? ?? '';
    final fee = (product['participationFee'] is num) ? (product['participationFee'] as num).toInt() : 0;
    final rate = product['commissionRate'];
    final ratePercent = rate is num ? (rate * 100).toStringAsFixed(0) : '0';
    final formattedFee = NumberFormat('#,###').format(fee);
    final hasVendor = vendorName.isNotEmpty;
    final items = product['items'] as List? ?? [];
    final productIndex = _products.indexOf(product);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: _getAccordionColor(product),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: !hasVendor ? AppColors.border
              : items.isEmpty ? const Color(0xFFFFCC80)   // 주황 테두리
              : const Color(0xFF81C784),                   // 초록 테두리
        ),
      ),
      // Row로 드래그 핸들과 ExpansionTile을 분리 (제스처 충돌 방지)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 드래그 핸들 — ExpansionTile 바깥에 배치하여 제스처 충돌 없음
          // PC: 클릭+드래그 즉시 반응, 모바일: 꾹 눌러서 드래그
          ReorderableDragStartListener(
            index: productIndex,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Container(
                width: 36, // 넉넉한 터치/클릭 영역
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: const Icon(Icons.drag_indicator, size: 22, color: AppColors.textHint),
              ),
            ),
          ),
          // ExpansionTile (나머지 영역 전체)
          Expanded(
            child: ExpansionTile(
        key: PageStorageKey(product['id']), // 상태 유지용 키
        shape: const Border(), // 펼쳤을 때 까만 줄 제거
        collapsedShape: const Border(), // 접혔을 때 까만 줄 제거
        initiallyExpanded: _expandedProductIds.contains(product['id']),
        onExpansionChanged: (expanded) {
          if (expanded) {
            _expandedProductIds.add(product['id']);
          } else {
            _expandedProductIds.remove(product['id']);
          }
        },
        title: Row(
          children: [
            // 품목 이름 + 입금 배지 (이름 바로 옆)
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 입금 상태 배지 (품목 이름 바로 옆)
                  if (hasVendor && fee > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: product['feePaymentConfirmed'] == true
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product['feePaymentConfirmed'] == true ? '입금' : '미입금',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: product['feePaymentConfirmed'] == true
                              ? const Color(0xFF4CAF50)
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 협력 업체 (드롭다운 선택)
          _buildVendorDropdownRow(product, vendorName),
          const SizedBox(height: 10),
          // 수수료
          _buildDetailRow(
            label: '수수료',
            value: '$ratePercent%',
            onEdit: () => _editField(product, '수수료', 'commissionRate', ratePercent),
          ),
          const SizedBox(height: 10),
          // 참가비
          _buildDetailRow(
            label: '참가비',
            value: '$formattedFee원',
            onEdit: () => _editField(product, '참가비', 'participationFee', fee.toString()),
          ),
          const SizedBox(height: 10),
          // 참가비 입금 확인 체크박스
          if (hasVendor && fee > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text('입금 확인', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _toggleFeePayment(product),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: product['feePaymentConfirmed'] == true
                            ? const Color(0xFFE8F5E9)  // 초록 배경
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: product['feePaymentConfirmed'] == true
                              ? const Color(0xFF81C784)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            product['feePaymentConfirmed'] == true
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 20,
                            color: product['feePaymentConfirmed'] == true
                                ? const Color(0xFF4CAF50)
                                : AppColors.textHint,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            product['feePaymentConfirmed'] == true ? '입금 완료' : '미입금',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: product['feePaymentConfirmed'] == true
                                  ? const Color(0xFF4CAF50)
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // 상세 품목 목록 (2뎁스)
          _buildItemsList(product),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 품목 이름 변경 + 삭제 + 업체 참가 취소 버튼
          Row(
            children: [
              // 이름 변경 버튼
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editField(product, '품목명', 'name', name),
                  icon: Image.asset('assets/icons/vendor/write.png', width: 18, height: 18, color: AppColors.organizer),
                  label: const Text('이름 변경'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.organizer,
                    side: const BorderSide(color: AppColors.organizer),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 품목 삭제 버튼
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteProductDialog(product),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('품목 삭제'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          // 업체 참가 취소 (업체 배정된 경우에만)
          if (hasVendor) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showUnclaimConfirmDialog(product),
                icon: const Icon(Icons.person_remove, size: 18),
                label: const Text('참가 취소'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
          ), // Expanded (ExpansionTile)
        ], // Row children
      ), // Row (드래그핸들 + ExpansionTile)
    );
  }

  // 상세 품목(2뎁스) 목록 표시
  Widget _buildItemsList(Map<String, dynamic> product) {
    final items = product['items'] as List<Map<String, dynamic>>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 80,
              child: Text('상세 품목', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ),
            const SizedBox(width: 12),
            Text(
              '${items.length}개 등록',
              style: TextStyle(
                fontSize: 14,
                color: items.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...items.map((item) {
            final formattedPrice = NumberFormat('#,###').format(item['price'] ?? 0);
            final types = (item['housingTypes'] as List?)?.join(', ') ?? '';
            return GestureDetector(
              onTap: () => _showItemDetailDialog(item, product['name'] ?? ''),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6, left: 92),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          if (types.isNotEmpty)
                            Text(types, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text('$formattedPrice원', style: const TextStyle(fontSize: 13, color: AppColors.priceRed, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 탭 2: 고객관리 (디자인: 6.주관사용-고객 관리.jpg)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildCustomerTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 고객 집계 > + 초대 버튼
          Row(
            children: [
              const Text('고객 집계', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
              const Spacer(),
              _buildInviteButton(),
            ],
          ),
          const SizedBox(height: 16),
          // 총 가입 고객 바 (주황)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.organizer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('총 가입 고객', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('총 ${_customers.length} 명', style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 고객 테이블 헤더 + 다운로드 버튼
          Row(
            children: [
              const Text('고객', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
              const Spacer(),
              // 선택 다운로드 (선택된 항목이 있을 때)
              if (_selectedCustomerIndices.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _downloadCustomerCsv(selectedOnly: true),
                  icon: const Icon(Icons.download, size: 16),
                  label: Text('선택 (${_selectedCustomerIndices.length})', style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.organizer),
                ),
              // 전체 다운로드
              TextButton.icon(
                onPressed: _customers.isEmpty ? null : () => _downloadCustomerCsv(selectedOnly: false),
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('전체', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppColors.organizer),
              ),
            ],
          ),
          // 테이블 헤더 (전체 선택 체크박스 포함)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                // 전체 선택 체크박스
                SizedBox(
                  width: 32,
                  child: Checkbox(
                    value: _customers.isNotEmpty && _selectedCustomerIndices.length == _customers.length,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedCustomerIndices.addAll(List.generate(_customers.length, (i) => i));
                        } else {
                          _selectedCustomerIndices.clear();
                        }
                      });
                    },
                    activeColor: AppColors.organizer,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const Expanded(flex: 2, child: Text('이름', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                const Expanded(flex: 1, child: Text('동', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                const Expanded(flex: 1, child: Text('호수', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                const Expanded(flex: 2, child: Text('연락처', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // 고객 목록 또는 로딩/빈 상태
          Expanded(
            child: _isLoadingCustomers
                ? const Center(child: CircularProgressIndicator(color: AppColors.organizer))
                : _customers.isEmpty
                    ? const Center(
                        child: Text('아직 참여한 고객이 없습니다', style: TextStyle(color: AppColors.textHint)),
                      )
                    : ListView.builder(
                        itemCount: _customers.length,
                        itemBuilder: (context, index) {
                          final customer = _customers[index];
                          final isSelected = _selectedCustomerIndices.contains(index);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedCustomerIndices.remove(index);
                                } else {
                                  _selectedCustomerIndices.add(index);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.organizer.withValues(alpha: 0.06) : null,
                                border: const Border(bottom: BorderSide(color: AppColors.background)),
                              ),
                              child: Row(
                                children: [
                                  // 개별 체크박스
                                  SizedBox(
                                    width: 32,
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedCustomerIndices.add(index);
                                          } else {
                                            _selectedCustomerIndices.remove(index);
                                          }
                                        });
                                      },
                                      activeColor: AppColors.organizer,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(customer['name'], style: const TextStyle(fontSize: 13)),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(customer['dong'], style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(customer['ho'], style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(customer['phone'], style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 탭 3: 계약함 (디자인: 7.주관사용-계약함.jpg)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildContractTab() {
    if (_isLoadingContracts) {
      return const Center(child: CircularProgressIndicator(color: AppColors.organizer));
    }

    // 집계 계산
    final activeContracts = _contracts.where((c) => c['status'] != 'CANCELLED').toList();
    final confirmedContracts = _contracts.where((c) => c['status'] == 'CONFIRMED').toList();
    final cancelRequestedCount = _contracts.where((c) => c['status'] == 'CANCEL_REQUESTED').length;
    final cancelledCount = _contracts.where((c) => c['status'] == 'CANCELLED').length;
    final totalDeposit = activeContracts.fold<int>(0, (sum, c) => sum + ((c['depositAmount'] as num?)?.toInt() ?? 0));
    final format = NumberFormat('#,###');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 계약 집계
          const Row(
            children: [
              Text('계약 집계', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          // 집계 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.summaryBar,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _SummaryRow(label: '판매 품목 수', value: '총 ${_products.length} 건'),
                const SizedBox(height: 8),
                _SummaryRow(label: '계약 건', value: '총 ${confirmedContracts.length} 건'),
                const SizedBox(height: 8),
                _SummaryRow(label: '취소 요청 건', value: '총 $cancelRequestedCount 건', valueColor: AppColors.priceRed),
                const SizedBox(height: 8),
                _SummaryRow(label: '취소 완료 건', value: '총 $cancelledCount 건'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 총 수입 금액 바 (주황)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.organizer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('총 수입 금액', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('${format.format(totalDeposit)}원', style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 계약 건 >
          const Row(
            children: [
              Text('계약 건', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          // 계약 목록 (고객별 그룹핑) 또는 빈 상태
          if (_contracts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('아직 계약 건이 없습니다', style: TextStyle(color: AppColors.textHint)),
              ),
            )
          else
            ..._buildGroupedContracts(),
        ],
      ),
    );
  }

  // 고객별 계약 그룹핑 (1뎁스: 고객, 2뎁스: 계약 건)
  List<Widget> _buildGroupedContracts() {
    // 고객 이름 기준으로 그룹핑
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final c in _contracts) {
      final customerKey = '${c['customerName']}|${c['customerAddress']}|${c['customerPhone']}';
      grouped.putIfAbsent(customerKey, () => []).add(c);
    }

    return grouped.entries.map((entry) {
      final parts = entry.key.split('|');
      final name = parts[0];
      final address = parts.length > 1 ? parts[1] : '';
      final phone = parts.length > 2 ? parts[2] : '';
      final contracts = entry.value;
      final activeCount = contracts.where((c) => c['status'] != 'CANCELLED').length;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (address.isNotEmpty)
                      Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('$name 님', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              // 계약 건수 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.organizer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeCount건',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white),
                ),
              ),
            ],
          ),
          // 2뎁스: 개별 계약 카드 목록
          children: contracts.map((contract) => _buildOrganizerContractCard(contract)).toList(),
        ),
      );
    }).toList();
  }

  // 주관사 계약 카드 (개별) — 클릭 시 상세보기
  Widget _buildOrganizerContractCard(Map<String, dynamic> contract) {
    final format = NumberFormat('#,###');
    final status = contract['status'] as String;

    // 상태별 뱃지
    String statusText;
    Color statusColor;
    Color statusBgColor;
    switch (status) {
      case 'CONFIRMED':
        statusText = '계약 완료';
        statusColor = AppColors.white;
        statusBgColor = AppColors.organizer;
        break;
      case 'CANCEL_REQUESTED':
        statusText = '취소 요청';
        statusColor = AppColors.white;
        statusBgColor = AppColors.priceRed;
        break;
      case 'CANCELLED':
        statusText = '취소 완료';
        statusColor = AppColors.textSecondary;
        statusBgColor = AppColors.border;
        break;
      default:
        statusText = '대기중';
        statusColor = AppColors.textPrimary;
        statusBgColor = AppColors.background;
    }

    return GestureDetector(
      onTap: () => _openContractDetail(contract),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 품목명 + 금액
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contract['productName'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${format.format(contract['originalPrice'])}원 / 계약금 ${format.format(contract['depositAmount'])}원',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            // 상태 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  // 계약 상세보기 (API로 전체 정보 조회 후 화면 이동)
  Future<void> _openContractDetail(Map<String, dynamic> contract) async {
    final contractId = contract['id']?.toString();
    if (contractId == null || contractId.isEmpty) return;

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.organizer)),
    );

    final result = await ContractService().getContractDetail(contractId);
    if (!mounted) return;
    Navigator.pop(context); // 로딩 닫기

    if (result['success'] == true) {
      final detail = result['contract'] as Map<String, dynamic>;
      // 행사 정보 보강
      detail['eventTitle'] = _eventDetail?['title'] ?? widget.eventTitle;
      detail['siteName'] = detail['siteName'] ?? _eventDetail?['siteName'] ?? '';
      detail['organizerName'] = detail['organizerName'] ?? _eventDetail?['organizer']?['name'] ?? '';

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CustomerContractDetailScreen(
            contract: detail,
            categoryName: contract['productCategory'] ?? '계약 상세',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계약 상세 정보를 불러올 수 없습니다')),
      );
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 탭 4: 알림
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 전체 읽음 처리
  Future<void> _markAllNotificationsAsRead() async {
    final result = await _notificationService.markAllAsRead();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = {..._notifications[i], 'isRead': true};
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 알림을 읽음으로 표시했습니다')),
      );
    }
  }

  Widget _buildNotificationTab() {
    if (_isLoadingNotifications) {
      return const Center(child: CircularProgressIndicator(color: AppColors.organizer));
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 48, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('알림이 없습니다', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // 읽지 않은 알림이 있는지 확인
    final hasUnread = _notifications.any((n) => n['isRead'] != true);

    return Column(
      children: [
        // 전체 읽음 버튼
        if (hasUnread)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _markAllNotificationsAsRead,
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('전부 읽음으로 표시', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: AppColors.organizer),
              ),
            ),
          ),
        Expanded(child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final noti = _notifications[index];
        final isRead = noti['isRead'] == true;
        final createdAt = noti['createdAt'] as String;
        final dateStr = createdAt.length >= 16 ? createdAt.substring(0, 16).replaceAll('T', ' ') : createdAt;

        // 알림 타입별 아이콘 + 색상
        final notiStyle = _getNotificationStyle(noti['type'] as String? ?? '');

        return GestureDetector(
          onTap: () async {
            // 읽음 처리
            if (!isRead) {
              await _notificationService.markAsRead(noti['id']);
              setState(() {
                _notifications[index] = {...noti, 'isRead': true};
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isRead ? AppColors.white : notiStyle['color'].withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isRead ? AppColors.border : notiStyle['color'].withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 알림 아이콘 (타입별 색상 적용)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isRead ? AppColors.background : notiStyle['color'].withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(notiStyle['icon'] as IconData, size: 18, color: isRead ? AppColors.textSecondary : notiStyle['color']),
                ),
                const SizedBox(width: 12),
                // 알림 내용
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        noti['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        noti['body'],
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                ),
                // 안 읽은 표시 (빨간 점)
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.priceRed,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    )),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 공통 위젯
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // 색상 범례 아이콘
  Widget _colorLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2), border: Border.all(color: AppColors.border)),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  // 초대 버튼
  // 고객 리스트 CSV(엑셀) 다운로드
  void _downloadCustomerCsv({required bool selectedOnly}) {
    final List<Map<String, dynamic>> targets;
    if (selectedOnly) {
      targets = _selectedCustomerIndices.map((i) => _customers[i]).toList();
    } else {
      targets = _customers;
    }
    if (targets.isEmpty) return;

    // CSV 행 구성 (헤더 + 데이터)
    final rows = <List<String>>[
      ['이름', '동', '호수', '타입', '연락처'], // 헤더
      ...targets.map((c) => [
        c['name'] ?? '',
        c['dong'] ?? '',
        c['ho'] ?? '',
        c['housingType'] ?? '',
        c['phone'] ?? '',
      ]),
    ];

    final eventTitle = _eventDetail?['title'] ?? widget.eventTitle;
    downloadCsv(rows, '${eventTitle}_고객리스트.csv');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${targets.length}명 고객 리스트 다운로드 완료')),
    );
  }

  // 알림 타입별 아이콘 + 색상 (통일된 색상 매뉴얼)
  Map<String, dynamic> _getNotificationStyle(String type) {
    switch (type) {
      case 'VENDOR_JOINED':
        return {'icon': Icons.person_add, 'color': const Color(0xFF4CAF50)}; // 초록 (참여)
      case 'PRODUCT_REGISTERED':
        return {'icon': Icons.inventory_2, 'color': const Color(0xFF2196F3)}; // 파랑 (등록)
      case 'PRODUCT_UPDATED':
        return {'icon': Icons.edit_note, 'color': const Color(0xFF9C27B0)}; // 보라 (수정)
      case 'CONTRACT_CREATED':
        return {'icon': Icons.description, 'color': const Color(0xFF2D6EFF)}; // 파랑 (계약)
      case 'CONTRACT_CONFIRMED':
        return {'icon': Icons.check_circle, 'color': const Color(0xFF4CAF50)}; // 초록 (확정)
      case 'CANCEL_REQUESTED':
        return {'icon': Icons.warning, 'color': Colors.orange}; // 주황 (취소요청)
      case 'CANCEL_APPROVED':
        return {'icon': Icons.cancel, 'color': const Color(0xFFE53935)}; // 빨강 (취소완료)
      case 'PAYMENT_COMPLETED':
        return {'icon': Icons.payment, 'color': const Color(0xFF4CAF50)}; // 초록 (결제)
      case 'PAYMENT_REFUNDED':
        return {'icon': Icons.money_off, 'color': const Color(0xFFE53935)}; // 빨강 (환불)
      default:
        return {'icon': Icons.notifications, 'color': const Color(0xFF757575)}; // 회색 (기타)
    }
  }

  Widget _buildInviteButton() {
    return GestureDetector(
      onTap: _showInviteDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline, size: 16, color: AppColors.textPrimary),
            SizedBox(width: 4),
            Text('초대', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // 참여 업체 목록 슬라이드 패널 (우측에서 열림)
  void _showVendorListPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // 핸들 바
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 제목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.groups_outlined, size: 22, color: AppColors.organizer),
                  const SizedBox(width: 8),
                  Text(
                    '참여 업체 목록 (${_vendors.length})',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Divider(),
            // 업체 리스트
            Expanded(
              child: _vendors.isEmpty
                  ? const Center(
                      child: Text('참여한 업체가 없습니다', style: TextStyle(color: AppColors.textHint)),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _vendors.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final vendor = _vendors[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.textPrimary,
                            radius: 20,
                            child: Text(
                              (vendor['name'] ?? '?').toString().isNotEmpty
                                  ? vendor['name'].toString()[0]
                                  : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                          title: Text(
                            vendor['name'] ?? '이름 없음',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          subtitle: vendor['phone'] != null
                              ? Text(vendor['phone'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 초대 다이얼로그 (고객 URL/QR + 코드 / 협력업체 코드)
  void _showInviteDialog() {
    // 고객/업체 참여 코드 (_eventDetail에서 우선 가져옴, 없으면 widget 파라미터 사용)
    final customerCode = _eventDetail?['entryCode']?.toString() ?? widget.entryCode ?? '------';
    final vendorCode = _eventDetail?['vendorEntryCode']?.toString() ?? widget.vendorEntryCode ?? '------';
    final inviteUrl = 'https://signnote.pages.dev/entry-code?code=$customerCode';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('초대하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 24),
            // 고객 입장 URL
            const Text('고객 입장 URL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildCopyField(inviteUrl),
            const SizedBox(height: 16),
            // 고객 입장 QR코드
            const Text('고객 입장 QR코드', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Center(
              child: QrImageView(
                data: inviteUrl,
                size: 160,
                backgroundColor: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            // 고객 입장코드
            const Text('고객 입장코드', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildCopyField(customerCode),
            const SizedBox(height: 16),
            // 협력업체 입장코드
            const Text('협력업체 입장코드', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildCopyField(vendorCode),
            const SizedBox(height: 12),
            // 협력업체 초대 메시지 전체 복사 버튼 (행사명+URL+코드 포함)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final vendorInviteUrl = 'https://signnote.pages.dev/entry-code?code=$vendorCode';
                  final fullMessage = '${widget.eventTitle}\n'
                      '입장 URL : $vendorInviteUrl\n'
                      '초대코드 : $vendorCode\n'
                      '위 링크로 입장하시거나 또는 앱에서 코드를 입력하세요.';
                  Clipboard.setData(ClipboardData(text: fullMessage));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('행사명 포함 초대 메시지가 복사되었습니다')),
                  );
                },
                icon: const Icon(Icons.content_copy, size: 16),
                label: const Text('행사명 포함 초대 메시지 복사'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.organizer,
                  side: const BorderSide(color: AppColors.organizer),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 복사 가능한 코드/URL 필드
  Widget _buildCopyField(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque, // 터치 영역 확대
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('복사되었습니다')),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(8), // 터치 영역 34x34로 확대
              child: Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // 협력 업체 드롭다운 행 (참여 업체 목록에서 선택)
  Widget _buildVendorDropdownRow(Map<String, dynamic> product, String currentVendorName) {
    final productId = product['id'].toString();
    final currentVendorId = product['vendorId']?.toString() ?? '';
    final hasVendor = currentVendorName.isNotEmpty;

    // 현재 배정된 업체가 드롭다운 목록에 있는지 확인 (있으면 선택값으로 표시)
    final vendorInList = hasVendor && _vendors.any((v) => v['id'] == currentVendorId);

    return Row(
      children: [
        const SizedBox(
          width: 80,
          child: Text('협력 업체', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                // 배정된 업체가 목록에 있으면 선택값으로 표시 (드롭다운 첫줄에 현재값 표시)
                value: vendorInList ? currentVendorId : null,
                hint: Text(
                  hasVendor ? currentVendorName : '업체 선택',
                  style: TextStyle(
                    fontSize: 14,
                    color: hasVendor ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                items: [
                  // 미배정 옵션 (첫 번째 줄)
                  const DropdownMenuItem<String>(value: '', child: Text('미배정', style: TextStyle(fontSize: 14, color: AppColors.textHint))),
                  ..._vendors.map((vendor) {
                    return DropdownMenuItem<String>(
                      value: vendor['id'],
                      child: Text(vendor['name'], style: const TextStyle(fontSize: 14)),
                    );
                  }),
                ],
                onChanged: (vendorId) {
                  if (vendorId == null) return;
                  if (vendorId.isEmpty) {
                    // 미배정 선택 → 업체 해제
                    _unassignVendor(productId);
                  } else {
                    _assignVendor(productId, vendorId);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 품목 순서 변경 (위/아래 이동)
  Future<void> _moveProduct(int from, int to) async {
    setState(() {
      final item = _products.removeAt(from);
      _products.insert(to, item);
    });

    // 서버에 새 순서 저장
    final productIds = _products.map((p) => p['id'].toString()).toList();
    await _productService.reorderProducts(widget.eventId, productIds);
  }

  // 참가비 입금 확인 토글
  Future<void> _toggleFeePayment(Map<String, dynamic> product) async {
    final productId = product['id'].toString();
    final currentValue = product['feePaymentConfirmed'] == true;
    final newValue = !currentValue;

    final result = await _productService.updateProduct(
      productId,
      {'feePaymentConfirmed': newValue},
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        product['feePaymentConfirmed'] = newValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newValue ? '입금 확인 완료' : '입금 확인 취소')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '입금 확인 처리에 실패했습니다')),
      );
    }
  }

  // 업체 배정 API 호출
  Future<void> _assignVendor(String productId, String vendorId) async {
    final result = await _productService.assignVendor(
      productId: productId,
      vendorId: vendorId,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업체가 배정되었습니다')),
      );
      _loadProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '업체 배정에 실패했습니다')),
      );
    }
  }

  // 업체 배정 해제 (미배정으로 되돌리기)
  Future<void> _unassignVendor(String productId) async {
    final result = await _productService.unclaimProduct(productId);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업체 배정이 해제되었습니다')),
      );
      _loadProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '배정 해제에 실패했습니다')),
      );
    }
  }

  // 상세 정보 행 (라벨 + 값 + 연필 아이콘)
  Widget _buildDetailRow({
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onEdit,
          child: Image.asset('assets/icons/vendor/write.png', width: 18, height: 18, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // 필드 수정 다이얼로그
  void _editField(
    Map<String, dynamic> product,
    String fieldLabel,
    String fieldKey,
    String currentValue,
  ) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('$fieldLabel 수정', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.right,
          keyboardType: (fieldKey == 'vendorName' || fieldKey == 'name') ? TextInputType.text : TextInputType.number,
          decoration: InputDecoration(
            hintText: '$fieldLabel 입력',
            suffixText: fieldKey == 'commissionRate' ? '%' : fieldKey == 'participationFee' ? '원' : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateProductField(product, fieldKey, controller.text);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.organizer),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // 서버에 필드 업데이트
  Future<void> _updateProductField(
    Map<String, dynamic> product,
    String fieldKey,
    String newValue,
  ) async {
    final productId = product['id'].toString();
    Map<String, dynamic> updateData = {};

    if (fieldKey == 'name') {
      updateData['name'] = newValue;
      updateData['category'] = newValue; // 품목명 = 카테고리 (동기화)
    } else if (fieldKey == 'vendorName') {
      updateData['vendorName'] = newValue;
    } else if (fieldKey == 'commissionRate') {
      final percent = double.tryParse(newValue) ?? 0;
      updateData['commissionRate'] = percent / 100;
    } else if (fieldKey == 'participationFee') {
      updateData['participationFee'] = parseCommaNumber(newValue);
    }

    final result = await _productService.updateProduct(productId, updateData);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정되었습니다')),
      );
      _loadProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '수정에 실패했습니다')),
      );
    }
  }

  // 상세 품목 상세보기 다이얼로그 (#7)
  void _showItemDetailDialog(Map<String, dynamic> item, String productName) {
    final formattedPrice = NumberFormat('#,###').format(item['price'] ?? 0);
    final types = (item['housingTypes'] as List?)?.join(', ') ?? '전체';
    final description = item['description'] as String? ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          item['name'] ?? '상세 품목',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상위 품목명
            _detailInfoRow('품목', productName),
            const SizedBox(height: 8),
            // 적용 타입
            _detailInfoRow('적용 타입', types),
            const SizedBox(height: 8),
            // 가격
            _detailInfoRow('가격', '$formattedPrice원'),
            // 설명
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              _detailInfoRow('설명', description),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // 상세보기 정보 행
  Widget _detailInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  // 품목 삭제 확인 다이얼로그
  void _showDeleteProductDialog(Map<String, dynamic> product) {
    final productName = product['name'] ?? '품목';
    final items = product['items'] as List? ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('품목 삭제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          '"$productName" 품목을 삭제하시겠습니까?'
          '${items.isNotEmpty ? '\n\n하위 상세 품목 ${items.length}개도 함께 삭제됩니다.' : ''}',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('아니오')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProduct(product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 품목 삭제 API 호출
  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final productId = product['id'].toString();
    final result = await _productService.deleteProduct(productId);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('품목이 삭제되었습니다')),
      );
      _loadProducts(); // 목록 새로고침
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '품목 삭제에 실패했습니다')),
      );
    }
  }

  // 업체 참가 취소 확인
  void _showUnclaimConfirmDialog(Map<String, dynamic> product) {
    final productName = product['name'] ?? '품목';
    final vendorName = product['vendorName'] ?? '업체';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('참가 취소', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          '"$productName" 품목에서\n"$vendorName" 업체의 참가를 취소하시겠습니까?\n\n⚠️ 업체가 등록한 상세 품목이 모두 삭제됩니다.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('아니오')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _unclaimProduct(product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('참가 취소'),
          ),
        ],
      ),
    );
  }

  // 업체 참가 취소 API
  Future<void> _unclaimProduct(Map<String, dynamic> product) async {
    final productId = product['id'].toString();
    final result = await _productService.unclaimProduct(productId);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업체 참가가 취소되었습니다')),
      );
      _loadProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '참가 취소에 실패했습니다')),
      );
    }
  }
}

// 계약 집계 행 (라벨 + 값)
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: valueColor ?? AppColors.white, fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor ?? AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
