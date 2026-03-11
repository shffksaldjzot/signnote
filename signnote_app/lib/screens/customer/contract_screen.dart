import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../services/contract_service.dart';
import '../../utils/image_download.dart';
import 'contract_detail_screen.dart';
import 'cart_screen.dart';

// ============================================
// 고객용 계약함 화면 (리뉴얼)
//
// 디자인 참고: 8.고객용-계약함.jpg
// - 1뎁스 품목별 그룹핑
// - 각 카드: 업체명 + 패키지명 + 설명 + 상태 뱃지 + 가격 + 상세보기
// - 하단: "계약서 전체 다운로드" 버튼
// ============================================

class CustomerContractScreen extends StatefulWidget {
  const CustomerContractScreen({super.key});

  @override
  State<CustomerContractScreen> createState() => _CustomerContractScreenState();
}

class _CustomerContractScreenState extends State<CustomerContractScreen> {
  final int _currentTabIndex = 2;

  List<Map<String, dynamic>> _contracts = [];
  bool _isLoading = true;
  String? _error;

  final ContractService _contractService = ContractService();
  final _priceFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  // 서버에서 내 계약 목록 불러오기
  Future<void> _loadContracts() async {
    setState(() { _isLoading = true; _error = null; });

    final result = await _contractService.getMyContracts();

    if (!mounted) return;

    if (result['success'] == true) {
      final contracts = List<Map<String, dynamic>>.from(result['contracts'] ?? []);
      setState(() {
        _contracts = contracts.map((c) {
          final vendor = c['product']?['vendor'] as Map<String, dynamic>?;
          final event = c['event'] as Map<String, dynamic>?;
          return {
            'id': c['id']?.toString() ?? '',
            'vendorName': c['product']?['vendorName'] ?? vendor?['name'] ?? c['vendorName'] ?? '업체명 없음',
            'vendorPhone': vendor?['phone'] ?? '',
            'vendorRepresentative': vendor?['representativeName'] ?? '',
            'vendorBusinessNumber': vendor?['businessNumber'] ?? c['vendorBusinessNumber'] ?? '',
            'vendorBusinessAddress': vendor?['businessAddress'] ?? '',
            'productName': c['productItem']?['name'] ?? c['product']?['name'] ?? c['productItemName'] ?? c['productName'] ?? '상품명 없음',
            'productCategory': c['product']?['category'] ?? c['productName'] ?? '기타',
            'description': c['productItem']?['description'] ?? c['product']?['description'] ?? '',
            'originalPrice': c['originalPrice'] ?? 0,
            'price': c['originalPrice'] ?? 0,
            'depositAmount': c['depositAmount'] ?? 0,
            'remainAmount': c['remainAmount'] ?? 0,
            'status': c['status'] ?? 'PENDING',
            // 행사/주관사 정보
            'eventId': c['eventId']?.toString() ?? event?['id']?.toString() ?? '',
            'eventTitle': event?['title'] ?? '',
            'siteName': event?['siteName'] ?? '',
            'organizerName': event?['organizer']?['name'] ?? '',
            // 고객 정보 (본인)
            'customerName': c['customerName'] ?? '',
            'customerPhone': c['customerPhone'] ?? '',
            'customerAddress': c['customerAddress'] ?? '',
            'customerDong': c['customerDong'] ?? '',
            'customerHo': c['customerHo'] ?? '',
            'customerHousingType': c['customerHousingType'] ?? '',
          };
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? '계약 목록을 불러올 수 없습니다';
        _isLoading = false;
      });
    }
  }

  // 카테고리별 그룹핑
  Map<String, List<Map<String, dynamic>>> get _groupedContracts {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final c in _contracts) {
      final cat = c['productCategory'] as String? ?? '기타';
      grouped.putIfAbsent(cat, () => []).add(c);
    }
    return grouped;
  }

  // 탭 클릭 시 화면 이동
  void _onTabChanged(int index) {
    if (index == _currentTabIndex) return;
    switch (index) {
      case 0: // 홈 탭 → 이전 화면(EventDetailScreen)으로 돌아가기
        Navigator.of(context).pop();
        break;
      case 1: // 장바구니 — 계약 목록에서 행사 정보 추출하여 이동
        if (_contracts.isNotEmpty) {
          // 첫 번째 계약에서 행사 정보 가져오기
          final firstContract = _contracts.first;
          final eventId = firstContract['eventId']?.toString() ?? '';
          final eventTitle = firstContract['eventTitle']?.toString() ?? '';
          if (eventId.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CartScreen(eventId: eventId, eventTitle: eventTitle)),
            );
          }
        }
        break;
      case 2: break; // 현재 탭
      case 3: // 마이페이지 — 돌아올 때 탭 상태 유지
        context.push(AppRoutes.mypage, extra: 'CUSTOMER');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      // 계약함 — 탭 화면이므로 뒤로가기 없음, 통일된 AppHeader 사용
      appBar: const AppHeader(title: '계약함', showBackButton: false),
      body: _buildBody(),
      bottomNavigationBar: AppTabBar.customer(
        currentIndex: _currentTabIndex,
        onTap: _onTabChanged,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return EmptyState(icon: Icons.error_outline, message: _error!, actionLabel: '다시 시도', onAction: _loadContracts);
    }
    if (_contracts.isEmpty) {
      return const EmptyState(icon: Icons.description_outlined, message: '계약 내역이 없습니다', subMessage: '행사에서 품목을 선택하고 계약해보세요');
    }

    final grouped = _groupedContracts;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Row(
                children: [
                  Text('계약함', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              // 카테고리별 그룹핑
              ...grouped.entries.map((entry) {
                final category = entry.key;
                final contracts = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카테고리 헤더
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(category, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    // 계약 카드들
                    ...contracts.map((c) => _buildContractCard(c)),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ],
          ),
        ),
        // 하단: 계약서 전체 다운로드 버튼
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _downloadAllContracts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('계약서 전체 다운로드'),
            ),
          ),
        ),
      ],
    );
  }

  // 전체 계약서 다운로드 (이미지 파일로 순차 다운로드)
  Future<void> _downloadAllContracts() async {
    if (_contracts.isEmpty) return;

    // 진행 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_contracts.length}건의 계약서를 다운로드합니다...')),
    );

    int downloadCount = 0;
    for (final contract in _contracts) {
      final success = await _downloadContractAsImage(contract);
      if (success) downloadCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$downloadCount건의 계약서가 다운로드되었습니다')),
      );
    }
  }

  // 개별 계약을 이미지로 다운로드 (오프스크린 렌더링)
  Future<bool> _downloadContractAsImage(Map<String, dynamic> contract) async {
    try {
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
          final customerName = contract['customerName'] ?? '고객';
          final productName = contract['productName'] ?? '품목';
          final date = DateFormat('yyyyMMdd').format(DateTime.now());
          final fileName = '계약서_${customerName}_${productName}_$date.png';
          await downloadImageBytes(bytes, fileName);
          overlay.remove();
          return true;
        }
      }
      overlay.remove();
    } catch (_) {
      // 실패 시 다음 건 진행
    }
    return false;
  }

  // 계약서 이미지 내용 위젯 (다운로드용 — 개별 상세보기와 동일한 형식)
  Widget _buildContractImageContent(Map<String, dynamic> contract) {
    final format = NumberFormat('#,###');
    final originalPrice = contract['originalPrice'] ?? contract['price'] ?? 0;
    final depositAmount = contract['depositAmount'] ?? 0;
    final remainAmount = contract['remainAmount'] ?? (originalPrice - depositAmount);
    final status = contract['status'] ?? 'PENDING';
    final depositLabel = status == 'CONFIRMED' || status == 'CANCEL_REQUESTED'
        ? '${format.format(depositAmount)}원 (결제 완료)'
        : '${format.format(depositAmount)}원';

    // 섹션 카드 빌더 (개별 상세보기와 동일)
    Widget buildSection(String title, List<Widget> children) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
    }

    Widget infoLine(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('$label : $value', style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
      );
    }

    Widget priceLine(String label, String value, {Color? color}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: color ?? AppColors.textPrimary, fontWeight: color != null ? FontWeight.w600 : FontWeight.w400)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          children: [
            Text('계약 내용', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        // 행사 정보
        buildSection('행사 정보', [
          infoLine('행사명', contract['eventTitle'] ?? '-'),
          infoLine('현장명', contract['siteName'] ?? '-'),
          infoLine('주관사', contract['organizerName'] ?? '-'),
        ]),
        const SizedBox(height: 16),
        // 업체 정보
        buildSection('업체 정보', [
          infoLine('업체명', contract['vendorName'] ?? '-'),
          infoLine('대표자', contract['vendorRepresentative'] ?? '-'),
          infoLine('연락처', contract['vendorPhone'] ?? '-'),
          if ((contract['vendorBusinessNumber'] as String?)?.isNotEmpty == true)
            infoLine('사업자번호', contract['vendorBusinessNumber']),
          if ((contract['vendorBusinessAddress'] as String?)?.isNotEmpty == true)
            infoLine('사업장 주소', contract['vendorBusinessAddress']),
        ]),
        const SizedBox(height: 16),
        // 고객 정보
        buildSection('고객 정보', [
          infoLine('고객명', contract['customerName'] ?? '-'),
          infoLine('연락처', contract['customerPhone'] ?? '-'),
          if ((contract['customerDong'] as String?)?.isNotEmpty == true ||
              (contract['customerHo'] as String?)?.isNotEmpty == true)
            infoLine('동/호수', '${contract['customerDong'] ?? ''}동 ${contract['customerHo'] ?? ''}호'),
          if ((contract['customerHousingType'] as String?)?.isNotEmpty == true)
            infoLine('타입', contract['customerHousingType']),
          if ((contract['customerAddress'] as String?)?.isNotEmpty == true)
            infoLine('주소', contract['customerAddress']),
        ]),
        const SizedBox(height: 16),
        // 계약 내용
        buildSection('계약 내용', [
          infoLine('패키지명', contract['productName'] ?? '-'),
          if ((contract['description'] as String?)?.isNotEmpty == true)
            infoLine('상세 내용', contract['description']),
        ]),
        const SizedBox(height: 16),
        // 계약 금액
        buildSection('계약 금액', [
          priceLine('가격', '${format.format(originalPrice)}원'),
          priceLine('계약금', depositLabel, color: AppColors.priceRed),
          priceLine('잔금', '${format.format(remainAmount)}원'),
        ]),
        const SizedBox(height: 16),
        // 결제 정보
        buildSection('결제 정보', [
          infoLine('결제 수단', contract['paymentMethod'] ?? '카드결제'),
          infoLine('카드/계좌', contract['paymentDetail'] ?? '-'),
          infoLine('결제일시', contract['paidAt'] ?? '-'),
        ]),
        const SizedBox(height: 24),
        // 환불 안내
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('계약금 먼저 결제 되며, 취소 환불 조항에 동의합니다.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 8),
              Text('지금 결제 하시면 모두 결제되는 것이 아니라 계약금만 결제되며, 잔금은 해당 업체와 직접 결제하시면 됩니다.\n취소 지정 기간 이후 취소 건은 계약금 환불은 어렵습니다.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  // 계약 카드
  Widget _buildContractCard(Map<String, dynamic> contract) {
    final status = contract['status'] as String;
    final price = contract['originalPrice'] ?? contract['price'] ?? 0;
    final deposit = contract['depositAmount'] ?? 0;
    final remain = contract['remainAmount'] ?? 0;

    // 상태 뱃지
    String statusText;
    Color statusBgColor;
    switch (status) {
      case 'CONFIRMED':
        statusText = '계약금 결제 완료';
        statusBgColor = AppColors.textPrimary;
        break;
      case 'CANCEL_REQUESTED':
        statusText = '취소 요청';
        statusBgColor = AppColors.priceRed;
        break;
      case 'CANCELLED':
        statusText = '취소 완료';
        statusBgColor = AppColors.textHint;
        break;
      default:
        statusText = '대기중';
        statusBgColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 업체명 + 상태 뱃지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(contract['vendorName'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(6)),
                child: Text(statusText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 패키지명
          Text(contract['productName'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          // 설명
          if ((contract['description'] as String?)?.isNotEmpty == true) ...[
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
                Text('가격 : ${_priceFormat.format(price)}원', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('계약금 : ${_priceFormat.format(deposit)}원', style: const TextStyle(fontSize: 14, color: AppColors.priceRed, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('잔금 : ${_priceFormat.format(remain)}원', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 상세보기 + 취소 요청 버튼
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CustomerContractDetailScreen(
                        contract: contract,
                        categoryName: contract['productCategory'] ?? '계약 상세',
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('상세보기', style: TextStyle(fontSize: 13)),
              ),
              // 취소는 전화 문의 후 협력업체에서 처리 (고객 직접 취소 불가)
            ],
          ),
        ],
      ),
    );
  }
}
