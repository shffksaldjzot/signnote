import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/product_service.dart';
import '../../services/event_service.dart';
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

  const OrganizerEventManageScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.entryCode,
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

  final ProductService _productService = ProductService();
  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProducts();
    _loadVendors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 서버에서 품목 목록 가져오기 (1뎁스 + 2뎁스 items 포함)
  Future<void> _loadProducts() async {
    setState(() { _isLoading = true; _error = null; });

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
            'vendorName': p['vendorName'] ?? '',
            'name': p['name'] ?? '품목명 없음',
            'imageUrl': p['image'],
            'participationFee': p['participationFee'] ?? 0,
            'commissionRate': p['commissionRate'] ?? 0,
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
        // 홈 아이콘 (뒤로가기)
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, size: 26),
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
        // 4개 탭
        bottom: TabBar(
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 탭 1: 품목 관리
          _buildProductTab(),
          // 탭 2: 고객관리
          _buildCustomerTab(),
          // 탭 3: 계약함
          _buildContractTab(),
          // 탭 4: 알림
          _buildNotificationTab(),
        ],
      ),
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
        // 총 N 품목
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '총 ${_products.length} 품목',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
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

  // 아코디언 품목 아이템
  Widget _buildAccordionItem(Map<String, dynamic> product) {
    final name = product['name'] ?? '';
    final vendorName = product['vendorName'] as String? ?? '';
    final fee = product['participationFee'] as int? ?? 0;
    final rate = product['commissionRate'];
    final ratePercent = rate is num ? (rate * 100).toStringAsFixed(0) : '0';
    final formattedFee = NumberFormat('#,###').format(fee);
    final hasVendor = vendorName.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        title: Text(
          name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
            return Container(
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
                ],
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
                Text('총 0 명', style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
                onPressed: () {
                  // 검색 기능 (추후)
                },
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
          // 빈 상태
          const Expanded(
            child: Center(
              child: Text('아직 참여한 고객이 없습니다', style: TextStyle(color: AppColors.textHint)),
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
          // 집계 카드 (어두운 배경)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.summaryBar,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                _SummaryRow(label: '판매 품목 수', value: '총 0 건'),
                SizedBox(height: 8),
                _SummaryRow(label: '계약 건', value: '총 0 건'),
                SizedBox(height: 8),
                _SummaryRow(label: '취소 요청 건', value: '총 0 건', valueColor: AppColors.priceRed),
                SizedBox(height: 8),
                _SummaryRow(label: '취소 완료 건', value: '총 0 건'),
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('총 수입 금액', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('0원', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 계약 건 > 전체 드롭다운
          const Row(
            children: [
              Text('계약 건', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          // 빈 상태
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text('아직 계약 건이 없습니다', style: TextStyle(color: AppColors.textHint)),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 탭 4: 알림
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildNotificationTab() {
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 공통 위젯
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
    final customerCode = widget.entryCode ?? '------';
    // 실제로는 서버에서 별도 협력업체 코드를 가져와야 하지만
    // 현재는 동일 코드 사용 (추후 분리)
    final vendorCode = customerCode;
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
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('복사되었습니다')),
              );
            },
            child: const Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // 협력 업체 드롭다운 행 (참여 업체 목록에서 선택)
  Widget _buildVendorDropdownRow(Map<String, dynamic> product, String currentVendorName) {
    final productId = product['id'].toString();
    final hasVendor = currentVendorName.isNotEmpty;

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
                value: null, // 항상 hint로 현재 값 표시
                hint: Text(
                  hasVendor ? currentVendorName : '업체 선택',
                  style: TextStyle(
                    fontSize: 14,
                    color: hasVendor ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                items: _vendors.map((vendor) {
                  return DropdownMenuItem<String>(
                    value: vendor['id'],
                    child: Text(vendor['name'], style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (vendorId) {
                  if (vendorId != null) {
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
          '"$productName" 품목에서\n"$vendorName" 업체의 참가를 취소하시겠습니까?\n\n취소하면 해당 품목은 다시 미배정 상태가 됩니다.',
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
