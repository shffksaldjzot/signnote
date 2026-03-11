import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/product_service.dart';
import '../../services/contract_service.dart';
import '../../services/event_service.dart';
import '../../utils/image_download.dart';
import '../../utils/image_helper.dart';
import '../../services/notification_service.dart';
import 'product_form_screen.dart';
import '../customer/contract_detail_screen.dart';

// ============================================
// 업체용 행사 상세 화면 (2차 디자인)
//
// 디자인 참고: 3.업체용-품목 상세-수정.jpg, 5.업체용-계약함-수정.jpg
// 상단: 홈 아이콘 + 행사명 + 사람 아이콘
// 3개 탭: 판매 품목 / 계약함 / 알림
// ============================================

class VendorEventDetailScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const VendorEventDetailScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<VendorEventDetailScreen> createState() => _VendorEventDetailScreenState();
}

class _VendorEventDetailScreenState extends State<VendorEventDetailScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final ImagePicker _imagePicker = ImagePicker();

  // 품목 데이터
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingProducts = true;
  String? _productError;

  // 계약 데이터
  List<Map<String, dynamic>> _contracts = [];
  bool _isLoadingContracts = true;
  String? _contractError;

  // 계약 선택 (다운로드용)
  final Set<String> _selectedContractIds = {};

  // 행사 상세 정보 (정보 카드용)
  Map<String, dynamic>? _eventDetail;

  // 행사 정보 카드 표시 여부 (기본: 접힌 상태)
  bool _showInfoCard = false;

  // 알림 데이터
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoadingNotifications = true;

  final ProductService _productService = ProductService();
  final ContractService _contractService = ContractService();
  final EventService _eventService = EventService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
    _loadContracts();
    _loadEventDetail();
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 내 품목 목록 가져오기 (1뎁스 + 2뎁스 items 포함)
  Future<void> _loadProducts() async {
    setState(() { _isLoadingProducts = true; _productError = null; });

    final result = await _productService.getMyProducts(eventId: widget.eventId);

    if (!mounted) return;

    if (result['success'] == true) {
      final List products = result['products'] ?? [];
      setState(() {
        _products = products.map<Map<String, dynamic>>((p) {
          // 2뎁스 상세 품목 목록
          final items = (p['items'] as List?)?.map<Map<String, dynamic>>((item) => {
            'id': item['id']?.toString() ?? '',
            'productId': p['id']?.toString() ?? '',
            'name': item['name'] ?? '패키지명 없음',
            'description': item['description'] ?? '',
            'price': item['price'] ?? 0,
            'imageUrl': item['image'],
            'housingTypes': item['housingTypes'] != null ? List<String>.from(item['housingTypes']) : <String>[],
          }).toList() ?? [];

          return {
            'id': p['id']?.toString() ?? '',
            'category': p['category'] ?? '기타',
            'vendorName': p['vendorName'] ?? '',
            'name': p['name'] ?? '품목명 없음',
            'items': items,
            // 참가비/수수료 (집계용)
            'participationFee': p['participationFee'] ?? 0,
            'commissionRate': p['commissionRate'] ?? 0,
          };
        }).toList();
        _isLoadingProducts = false;
      });
    } else {
      setState(() {
        _productError = result['error'] ?? '품목을 불러올 수 없습니다';
        _isLoadingProducts = false;
      });
    }
  }

  // 계약 목록 가져오기 (현재 행사의 계약만 필터링)
  Future<void> _loadContracts() async {
    setState(() { _isLoadingContracts = true; _contractError = null; });

    final result = await _contractService.getVendorContracts(eventId: widget.eventId);

    if (!mounted) return;

    if (result['success'] == true) {
      final List contracts = result['contracts'] ?? [];
      setState(() {
        _contracts = contracts.map<Map<String, dynamic>>((c) => {
          'id': c['id']?.toString() ?? '',
          'customerName': c['customerName'] ?? c['customer']?['name'] ?? '고객',
          'customerAddress': c['customerAddress'] ?? '',
          'customerPhone': c['customerPhone'] ?? '',
          'customerDong': c['customerDong'] ?? '',
          'customerHo': c['customerHo'] ?? '',
          'customerHousingType': c['customerHousingType'] ?? '',
          'productName': c['productName'] ?? c['product']?['name'] ?? '상품명 없음',
          'productCategory': c['productCategory'] ?? c['product']?['category'] ?? '기타',
          'description': c['productDescription'] ?? c['product']?['description'] ?? '',
          'price': c['price'] ?? c['product']?['price'] ?? 0,
          'originalPrice': c['originalPrice'] ?? 0,
          'depositAmount': c['depositAmount'] ?? 0,
          'remainAmount': c['remainAmount'] ?? 0,
          'status': c['status'] ?? 'CONFIRMED',
          'vendorId': c['vendorId'] ?? '',
        }).toList();
        _isLoadingContracts = false;
      });
    } else {
      setState(() {
        _contractError = result['error'] ?? '계약을 불러올 수 없습니다';
        _isLoadingContracts = false;
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

  // 행사 정보 카드 수동 접기/펼치기 토글
  void _toggleInfoCard() {
    setState(() => _showInfoCard = !_showInfoCard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        // 홈 아이콘
        leading: IconButton(
          icon: Image.asset('assets/icons/vendor/home_inactive.png', width: 26, height: 26),
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
          // 사람 아이콘
          IconButton(
            icon: const Icon(Icons.person_outline, size: 26),
            onPressed: () => context.push(AppRoutes.mypage, extra: 'VENDOR'),
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
          // 3개 탭
          TabBar(
          controller: _tabController,
          labelColor: AppColors.vendor, // 검정
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.vendor,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          tabs: [
            const Tab(text: '판매 품목'),
            const Tab(text: '계약함'),
            // 알림 탭에 읽지 않은 수 배지 표시
            Tab(child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('알림'),
                if (_notifications.any((n) => n['isRead'] != true)) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_notifications.where((n) => n['isRead'] != true).length}',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            )),
          ],
          ),
          // 탭 내용 (스크롤 감지)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductTab(),
                _buildContractTab(),
                _buildNotificationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 행사 정보 카드 (제목과 탭 사이) — 주관사 이름 포함
  Widget _buildEventInfoCard() {
    if (_eventDetail == null) return const SizedBox.shrink();

    final organizerName = _eventDetail!['organizer']?['name'] ?? '';
    final siteName = _eventDetail!['siteName'] ?? '';
    final startDate = _eventDetail!['startDate']?.toString().substring(0, 10) ?? '';
    final endDate = _eventDetail!['endDate']?.toString().substring(0, 10) ?? '';
    final unitCount = _eventDetail!['unitCount'] ?? 0;
    final housingTypes = (_eventDetail!['housingTypes'] as List?)?.join(', ') ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // 연한 회색 배경 (업체용)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (organizerName.isNotEmpty) ...[
            _vendorInfoRow('주관사', organizerName),
            const SizedBox(height: 6),
          ],
          if (siteName.isNotEmpty) ...[
            _vendorInfoRow('현장명', siteName),
            const SizedBox(height: 6),
          ],
          if (startDate.isNotEmpty)
            _vendorInfoRow('기  간', '$startDate ~ $endDate'),
          if (unitCount > 0) ...[
            const SizedBox(height: 6),
            _vendorInfoRow('세대수', '${NumberFormat('#,###').format(unitCount)} 세대'),
          ],
          if (housingTypes.isNotEmpty) ...[
            const SizedBox(height: 6),
            _vendorInfoRow('평  형', housingTypes),
          ],
        ],
      ),
    );
  }

  // 정보 카드 행 (라벨 + 값)
  Widget _vendorInfoRow(String label, String value) {
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
  // 탭 1: 판매 품목
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildProductTab() {
    return Column(
      children: [
        // "판매 품목 리스트 >"
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: const [
              Text('판매 품목 리스트', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
        // 품목 목록
        Expanded(child: _buildProductList()),
        // 하단: "품목 추가하기" 검정 버튼
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                // 배정된 품목이 없으면 알림만 표시
                if (_products.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('배정된 품목이 없습니다. 주관사에게 품목 배정을 요청하세요.')),
                  );
                  return;
                }
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => VendorProductFormScreen(eventId: widget.eventId),
                  ),
                );
                if (result == true) _loadProducts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vendor,
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

  // 품목 목록 (1뎁스 아코디언 → 2뎁스 카드)
  Widget _buildProductList() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator(color: AppColors.vendor));
    }
    if (_productError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(_productError!, style: const TextStyle(color: AppColors.textSecondary)),
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
            Text('배정된 품목이 없습니다', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            SizedBox(height: 4),
            Text('주관사에서 품목을 배정받은 후\n아래 버튼으로 상세 품목을 추가하세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: _products.map((product) => _buildProductAccordion(product)).toList(),
    );
  }

  // 1뎁스 품목 아코디언 (줄눈, 나노코팅 등) → 내부에 2뎁스 카드
  Widget _buildProductAccordion(Map<String, dynamic> product) {
    final items = product['items'] as List<Map<String, dynamic>>? ?? [];
    final category = product['category'] as String? ?? product['name'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        shape: const Border(), // 펼쳤을 때 까만 줄 제거
        collapsedShape: const Border(), // 접혔을 때 까만 줄 제거
        title: Row(
          children: [
            Expanded(
              child: Text(category, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            // 상세 품목 개수 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.vendor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${items.length}개', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        initiallyExpanded: true,
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('등록된 상세 품목이 없습니다\n아래 "품목 추가하기" 버튼으로 추가하세요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textHint)),
            )
          else
            // 1뎁스당 첫 번째 item만 이미지 표시, 나머지는 이미지 없음
            ...items.asMap().entries.map((entry) =>
              _buildProductItemCard(entry.value, product, isFirstItem: entry.key == 0)),
        ],
      ),
    );
  }

  // 갤러리에서 이미지 선택 → 서버에 업데이트
  Future<void> _pickAndUploadImage(Map<String, dynamic> item) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 70,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final b64 = base64Encode(bytes);
    final mime = picked.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    final dataUrl = 'data:$mime;base64,$b64';

    final result = await _productService.updateProductItem(
      item['id'].toString(),
      {'image': dataUrl},
    );
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지가 업데이트되었습니다')),
      );
      _loadProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '이미지 업로드에 실패했습니다')),
      );
    }
  }

  // 2뎁스 상세 품목 카드 (이미지 + 이름 + 설명 + 가격 + 수정)
  // isFirstItem: 1뎁스당 첫 번째 item만 이미지 표시
  Widget _buildProductItemCard(Map<String, dynamic> item, Map<String, dynamic> parentProduct, {bool isFirstItem = false}) {
    final formattedPrice = NumberFormat('#,###').format(item['price']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 첫 번째 item만 이미지 영역 표시
          if (isFirstItem) ...[
            GestureDetector(
              onTap: () => _pickAndUploadImage(item),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.background,
                  child: (item['imageUrl'] != null && (item['imageUrl'] as String).isNotEmpty)
                      ? buildSmartImage(
                          item['imageUrl'] as String?,
                          width: 72,
                          height: 72,
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 24, color: AppColors.textHint),
                            SizedBox(height: 2),
                            Text('이미지 추가', style: TextStyle(fontSize: 9, color: AppColors.textHint)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            // 이미지 없는 item은 동일한 너비로 들여쓰기 (라인 정렬)
            const SizedBox(width: 84),
          ],
          // 품목 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 패키지명
                Text(item['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                // 설명
                if ((item['description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item['description'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                // 적용 타입
                if ((item['housingTypes'] as List).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text((item['housingTypes'] as List).join(', '), style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                ],
                const SizedBox(height: 6),
                // 가격 + 수정 아이콘
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        const TextSpan(text: '가격 : ', style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                        TextSpan(text: '$formattedPrice원', style: const TextStyle(fontSize: 14, color: AppColors.priceRed, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => VendorProductFormScreen(
                              eventId: widget.eventId,
                              product: item,
                              preSelectedProductId: parentProduct['id'],
                            ),
                          ),
                        );
                        if (result == true) _loadProducts();
                      },
                      child: Image.asset('assets/icons/vendor/write.png', width: 20, height: 20, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 탭 2: 계약함 (디자인: 5.업체용-계약함-수정.jpg)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildContractTab() {
    if (_isLoadingContracts) {
      return const Center(child: CircularProgressIndicator(color: AppColors.vendor));
    }
    if (_contractError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(_contractError!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadContracts, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    // 집계 계산
    final activeContracts = _contracts.where((c) => c['status'] != 'CANCELLED').toList();
    final totalDeposit = activeContracts.fold<int>(0, (sum, c) => sum + ((c['depositAmount'] as num?)?.toInt() ?? 0));
    // 수수료 20% 가정 (실제론 품목별 수수료율 사용해야 하나, 현재 간소화)
    final totalFee = (totalDeposit * 0.2).toInt();
    final totalRevenue = totalDeposit - totalFee;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 계약 집계 >
                const Row(
                  children: [
                    Text('계약 집계', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                // 집계 내용
                _buildContractSummaryRow('계약금 총 결제 금액', '${NumberFormat('#,###').format(totalDeposit)}원'),
                const SizedBox(height: 8),
                _buildContractSummaryRow('주관사 총 수수료', '${NumberFormat('#,###').format(totalFee)}원'),
                const SizedBox(height: 8),
                // 총 수익금 (강조)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.vendor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('총 수익금', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('${NumberFormat('#,###').format(totalRevenue)}원', style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '※카드사 수수료를 제외한 수익 금액으로 정산 시 카드 수수료를 제외 한 금액이 정산됩니다.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // 카테고리별 아코디언 (품목별 참가비/수수료/계약건)
                ..._buildCategoryContractSummaries(),

                const SizedBox(height: 24),
                // 계약 건 >
                Row(
                  children: [
                    const Text('계약 건', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                    const Spacer(),
                    // 전체 드롭다운
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('전체', style: TextStyle(fontSize: 13)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.search, size: 22, color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 16),

                // 계약 카드 목록
                if (_contracts.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text('아직 계약 건이 없습니다', style: TextStyle(color: AppColors.textHint)),
                    ),
                  )
                else
                  ..._buildContractCards(),
              ],
            ),
          ),
        ),
        // 하단: "다운로드" 검정 버튼
        if (_contracts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedContractIds.isEmpty
                    ? () {
                        // 선택 없으면 전체 다운로드 안내
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('다운로드할 계약을 선택해 주세요 (원형 체크박스 클릭)')),
                        );
                      }
                    : _downloadSelectedContracts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vendor,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: Text(
                  _selectedContractIds.isEmpty
                      ? '다운로드'
                      : '다운로드 (${_selectedContractIds.length}건)',
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 집계 행 (라벨 + 값)
  Widget _buildContractSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // 카테고리별 계약 집계 아코디언
  List<Widget> _buildCategoryContractSummaries() {
    // 카테고리별로 그룹핑
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final c in _contracts) {
      final cat = c['productCategory'] as String? ?? '기타';
      grouped.putIfAbsent(cat, () => []).add(c);
    }

    // 품목 데이터에서 참가비/수수료율 가져오기
    return grouped.entries.map((entry) {
      final category = entry.key;
      final contracts = entry.value;
      final totalCount = contracts.length;
      final cancelRequestCount = contracts.where((c) => c['status'] == 'CANCEL_REQUESTED').length;
      final cancelDoneCount = contracts.where((c) => c['status'] == 'CANCELLED').length;

      // 해당 카테고리의 품목 데이터에서 참가비/수수료 가져오기
      final matchingProduct = _products.firstWhere(
        (p) => p['category'] == category,
        orElse: () => <String, dynamic>{},
      );
      final participationFee = matchingProduct['participationFee'] ?? 0;
      final commissionRate = matchingProduct['commissionRate'] ?? 0;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ExpansionTile(
          shape: const Border(), // 펼쳤을 때 까만 줄 제거
          collapsedShape: const Border(), // 접혔을 때 까만 줄 제거
          title: Text(category, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildInfoRow('참가비', '${NumberFormat('#,###').format(participationFee)}원'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('수수료', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('수수료는 주관사가 설정한 비율입니다')),
                    );
                  },
                  child: const Icon(Icons.help_outline, size: 16, color: AppColors.textHint),
                ),
                const Spacer(),
                Text(
                  commissionRate is num ? '${(commissionRate * 100).toStringAsFixed(0)}%' : '0%',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildInfoRow('계약건', '총 $totalCount건'),
            const SizedBox(height: 6),
            _buildInfoRow('취소 요청 건', '총 $cancelRequestCount건', valueColor: AppColors.priceRed),
            const SizedBox(height: 6),
            _buildInfoRow('취소 완료 건', '총 $cancelDoneCount건'),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: valueColor ?? AppColors.textPrimary)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }

  // 계약 카드 목록 (카테고리 아코디언 내부에 카드)
  List<Widget> _buildContractCards() {
    // 카테고리별 그룹핑
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final c in _contracts) {
      final cat = c['productCategory'] as String? ?? '기타';
      grouped.putIfAbsent(cat, () => []).add(c);
    }

    return grouped.entries.map((entry) {
      final category = entry.key;
      final contracts = entry.value;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ExpansionTile(
          shape: const Border(), // 펼쳤을 때 까만 줄 제거
          collapsedShape: const Border(), // 접혔을 때 까만 줄 제거
          title: Text(category, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          initiallyExpanded: true,
          children: contracts.map((contract) => _buildContractCard(contract)).toList(),
        ),
      );
    }).toList();
  }

  // 선택된 계약 다운로드 (각각 이미지로)
  Future<void> _downloadSelectedContracts() async {
    final selectedContracts = _contracts.where((c) => _selectedContractIds.contains(c['id'])).toList();

    for (final contract in selectedContracts) {
      await _downloadContractAsImage(contract);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedContracts.length}건의 계약서가 다운로드되었습니다')),
      );
    }
  }

  // 개별 계약을 이미지로 다운로드
  Future<void> _downloadContractAsImage(Map<String, dynamic> contract) async {
    try {
      // 캡처할 위젯을 OverlayEntry로 렌더링
      final captureKey = GlobalKey();

      final overlay = OverlayEntry(
        builder: (_) => Positioned(
          left: -9999,
          child: Material(
            child: RepaintBoundary(
              key: captureKey,
              child: Container(
                width: 400,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: _buildContractImageContent(contract),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlay);
      await Future.delayed(const Duration(milliseconds: 200));

      final boundary = captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();
          final fileName = '계약서_${contract['customerName']}_${contract['productName']}_${DateTime.now().millisecondsSinceEpoch}.png';
          await downloadImageBytes(bytes, fileName);
        }
      }

      overlay.remove();
    } catch (e) {
      // 다운로드 실패 시 무시하고 다음 건 진행
    }
  }

  // 계약서 이미지 내용 위젯
  Widget _buildContractImageContent(Map<String, dynamic> contract) {
    final format = NumberFormat('#,###');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('계약서', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        // 고객 정보 (동/호수 포함)
        if ((contract['customerDong'] as String?)?.isNotEmpty == true)
          Text('동/호수: ${contract['customerDong']}동 ${contract['customerHo']}호${(contract['customerHousingType'] as String?)?.isNotEmpty == true ? ' (${contract['customerHousingType']})' : ''}', style: const TextStyle(fontSize: 13)),
        if ((contract['customerAddress'] as String?)?.isNotEmpty == true)
          Text('주소: ${contract['customerAddress']}', style: const TextStyle(fontSize: 13)),
        Text('${contract['customerName']} 님 / ${contract['customerPhone']}', style: const TextStyle(fontSize: 13)),
        const Divider(height: 24),
        Text('품목: ${contract['productName']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        if ((contract['description'] as String).isNotEmpty)
          Text(contract['description'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        Text('가격: ${format.format(contract['originalPrice'] ?? contract['price'])}원', style: const TextStyle(fontSize: 14)),
        Text('계약금: ${format.format(contract['depositAmount'])}원', style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w600)),
        Text('잔금: ${format.format(contract['remainAmount'])}원', style: const TextStyle(fontSize: 14)),
        const Divider(height: 24),
        Text('행사: ${widget.eventTitle}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text('발행일: ${DateFormat('yyyy.MM.dd').format(DateTime.now())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // 개별 계약 카드
  Widget _buildContractCard(Map<String, dynamic> contract) {
    final status = contract['status'] as String;
    final formattedPrice = NumberFormat('#,###').format(contract['originalPrice'] ?? contract['price']);
    final formattedDeposit = NumberFormat('#,###').format(contract['depositAmount']);
    final formattedRemain = NumberFormat('#,###').format(contract['remainAmount']);

    // 상태 뱃지
    String statusText;
    Color statusColor;
    Color statusBgColor;
    switch (status) {
      case 'CONFIRMED':
        statusText = '계약금 결제 완료';
        statusColor = AppColors.white;
        statusBgColor = AppColors.vendor;
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

    final contractId = contract['id'] as String;
    final isSelected = _selectedContractIds.contains(contractId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? AppColors.vendor : AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선택 체크박스 + 고객 정보 + 상태 뱃지
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 선택 원형 체크박스
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedContractIds.remove(contractId);
                    } else {
                      _selectedContractIds.add(contractId);
                    }
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 10, top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? AppColors.vendor : AppColors.border, width: 2),
                    color: isSelected ? AppColors.vendor : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: AppColors.white)
                      : null,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 동/호수 + 타입 표시 (있으면 동호수, 없으면 주소)
                    Text(
                      (contract['customerDong'] as String?)?.isNotEmpty == true
                        ? '${contract['customerDong']}동 ${contract['customerHo']}호${(contract['customerHousingType'] as String?)?.isNotEmpty == true ? ' (${contract['customerHousingType']})' : ''}'
                        : contract['customerAddress'] ?? '',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text('${contract['customerName']} 님', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
          // 상품명 + 설명
          Text(contract['productName'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          if ((contract['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(contract['description'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
          // 가격/계약금/잔금
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('가격 : $formattedPrice원', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('계약금 : $formattedDeposit원', style: const TextStyle(fontSize: 14, color: AppColors.priceRed, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('잔금 : $formattedRemain원', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 상세보기 버튼 (고객 계약 상세 화면 통일)
          OutlinedButton(
            onPressed: () => _openContractDetail(contract),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('상세보기', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // 계약 상세보기 (고객 계약 상세 화면으로 통일)
  Future<void> _openContractDetail(Map<String, dynamic> contract) async {
    final contractId = contract['id']?.toString();
    if (contractId == null || contractId.isEmpty) return;

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.vendor)),
    );

    final result = await _contractService.getContractDetail(contractId);
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
  // 탭 3: 알림
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // 알림 목록 가져오기
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
    }
  }

  // 알림 타입별 아이콘 + 색상 (통일된 색상 매뉴얼)
  Map<String, dynamic> _getNotificationStyle(String type) {
    switch (type) {
      case 'VENDOR_JOINED':
        return {'icon': Icons.person_add, 'color': const Color(0xFF4CAF50)};
      case 'PRODUCT_REGISTERED':
        return {'icon': Icons.inventory_2, 'color': const Color(0xFF2196F3)};
      case 'PRODUCT_UPDATED':
        return {'icon': Icons.edit_note, 'color': const Color(0xFF9C27B0)};
      case 'CONTRACT_CREATED':
        return {'icon': Icons.description, 'color': const Color(0xFF2D6EFF)};
      case 'CONTRACT_CONFIRMED':
        return {'icon': Icons.check_circle, 'color': const Color(0xFF4CAF50)};
      case 'CANCEL_REQUESTED':
        return {'icon': Icons.warning, 'color': Colors.orange};
      case 'CANCEL_APPROVED':
        return {'icon': Icons.cancel, 'color': const Color(0xFFE53935)};
      case 'PAYMENT_COMPLETED':
        return {'icon': Icons.payment, 'color': const Color(0xFF4CAF50)};
      case 'PAYMENT_REFUNDED':
        return {'icon': Icons.money_off, 'color': const Color(0xFFE53935)};
      default:
        return {'icon': Icons.notifications, 'color': const Color(0xFF757575)};
    }
  }

  Widget _buildNotificationTab() {
    if (_isLoadingNotifications) {
      return const Center(child: CircularProgressIndicator(color: AppColors.vendor));
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
                style: TextButton.styleFrom(foregroundColor: AppColors.vendor),
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
                  color: isRead ? AppColors.white : (notiStyle['color'] as Color).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isRead ? AppColors.border : (notiStyle['color'] as Color).withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 알림 아이콘 (타입별 색상 적용)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isRead ? AppColors.background : (notiStyle['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(notiStyle['icon'] as IconData, size: 18, color: isRead ? AppColors.textSecondary : notiStyle['color'] as Color),
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
}
