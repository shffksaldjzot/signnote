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

  // 행사 정보 카드 표시 여부 (스크롤로 접히기)
  bool _showInfoCard = true;

  // 아코디언 펼침 상태 유지 (리빌드 시에도 유지)
  final Set<String> _expandedProductIds = {};

  // 고객 목록 데이터
  List<Map<String, dynamic>> _customers = [];
  bool _isLoadingCustomers = true;

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
          'productName': c['productItem']?['name'] ?? c['product']?['name'] ?? '품목',
          'productCategory': c['product']?['category'] ?? '기타',
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

  // 스크롤 방향 감지 → 정보 카드 접기/펼치기
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 2 && _showInfoCard) {
        setState(() => _showInfoCard = false); // 위로 스크롤 → 카드 숨김
      } else if (delta < -2 && !_showInfoCard) {
        setState(() => _showInfoCard = true); // 아래로 스크롤 → 카드 표시
      }
    }
    return false;
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
        title: Text(
          widget.eventTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // 사람 아이콘 (마이페이지)
          IconButton(
            icon: const Icon(Icons.person_outline, size: 26),
            onPressed: () => context.push(AppRoutes.mypage, extra: 'ORGANIZER'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 행사 정보 카드 (스크롤 시 접힘/펼침)
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
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: _products.map((product) => _buildAccordionItem(product)).toList(),
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
    final fee = product['participationFee'] as int? ?? 0;
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
            // 순서 변경 버튼 (위/아래)
            if (productIndex > 0)
              GestureDetector(
                onTap: () => _moveProduct(productIndex, productIndex - 1),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_upward, size: 18, color: AppColors.textSecondary),
                ),
              ),
            if (productIndex < _products.length - 1)
              GestureDetector(
                onTap: () => _moveProduct(productIndex, productIndex + 1),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_downward, size: 18, color: AppColors.textSecondary),
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
          // 업체 참가 취소
          if (hasVendor) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
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
          // 고객 테이블 헤더
          Row(
            children: [
              const Text('고객', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search, size: 22),
                onPressed: () {},
              ),
            ],
          ),
          // 테이블 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('이름', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                Expanded(flex: 1, child: Text('동', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text('호수', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('연락처', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
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
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.background)),
                            ),
                            child: Row(
                              children: [
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
          // 계약 목록 또는 빈 상태
          if (_contracts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('아직 계약 건이 없습니다', style: TextStyle(color: AppColors.textHint)),
              ),
            )
          else
            ..._contracts.map((contract) => _buildOrganizerContractCard(contract)),
        ],
      ),
    );
  }

  // 주관사 계약 카드 (개별)
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 고객 정보 + 상태 뱃지
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((contract['customerAddress'] as String).isNotEmpty)
                      Text(contract['customerAddress'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text('${contract['customerName']} 님', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    if ((contract['customerPhone'] as String).isNotEmpty)
                      Text(contract['customerPhone'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 품목명
          Text(contract['productName'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // 금액
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('가격 : ${format.format(contract['originalPrice'])}원', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('계약금 : ${format.format(contract['depositAmount'])}원', style: const TextStyle(fontSize: 14, color: AppColors.priceRed, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('잔금 : ${format.format(contract['remainAmount'])}원', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
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

        // 알림 타입별 아이콘
        IconData icon;
        switch (noti['type']) {
          case 'VENDOR_JOINED':
            icon = Icons.person_add;
            break;
          case 'PRODUCT_REGISTERED':
            icon = Icons.inventory_2;
            break;
          case 'PRODUCT_UPDATED':
            icon = Icons.edit;
            break;
          case 'CONTRACT_CREATED':
          case 'CONTRACT_CONFIRMED':
            icon = Icons.description;
            break;
          case 'CANCEL_REQUESTED':
            icon = Icons.cancel;
            break;
          default:
            icon = Icons.notifications;
        }

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
              color: isRead ? AppColors.white : const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isRead ? AppColors.border : const Color(0xFFFFE0B2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 알림 아이콘
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isRead ? AppColors.background : const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: isRead ? AppColors.textSecondary : AppColors.organizer),
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
                  if (vendorId != null && vendorId.isNotEmpty) {
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
          child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
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
          keyboardType: fieldKey == 'vendorName' ? TextInputType.text : TextInputType.number,
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

    if (fieldKey == 'vendorName') {
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
