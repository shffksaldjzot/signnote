import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../services/cart_service.dart';
import '../../services/contract_service.dart';
import '../../services/event_service.dart';
import 'payment_screen.dart';

// ============================================
// 장바구니 화면
//
// 디자인 참고: 7.고객용-장바구니.jpg
// - 상단: 행사명 헤더 + "장바구니 >" 부제목
// - 1뎁스 품목별 카드 (업체명+패키지명+설명+가격/계약금/잔금+상세보기+삭제)
// - 총 견적 바 (계약 총액 / 계약금 총액 / 잔금 총액)
// - 동의 체크박스 + 상세 안내 문구
// - "계약금 결제하기 + 금액" 버튼
// ============================================

class CartScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final bool embedded; // true이면 Scaffold/AppBar/BottomNav 없이 body만 반환

  const CartScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.embedded = false,
  });

  @override
  State<CartScreen> createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final ContractService _contractService = ContractService();
  final EventService _eventService = EventService();

  // 장바구니 항목 목록 (서버에서 불러옴)
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  bool _isContractLoading = false;
  bool _agreedToTerms = false; // 동의 체크박스 상태
  String? _error;
  double _defaultDepositRate = AppConstants.depositRate; // 행사 기본 계약금 비율
  String? _cancelDeadlineStart; // 취소 가능 시작일
  String? _cancelDeadlineEnd;   // 취소 가능 종료일

  // 외부에서 호출 가능한 새로고침 메서드 (탭 전환 시 사용)
  void reload() {
    _loadCartItems();
    _loadEventDepositRate();
  }

  @override
  void initState() {
    super.initState();
    _loadCartItems();
    _loadEventDepositRate();
  }

  // 행사의 계약금 비율 가져오기
  Future<void> _loadEventDepositRate() async {
    final result = await _eventService.getEventDetail(widget.eventId);
    if (!mounted) return;
    if (result['success'] == true) {
      final event = result['event'] as Map<String, dynamic>? ?? {};
      final rate = event['depositRate'];
      setState(() {
        if (rate != null) {
          _defaultDepositRate = (rate as num).toDouble();
        }
        // 취소 지정 기간 저장
        _cancelDeadlineStart = event['cancelDeadlineStart']?.toString();
        _cancelDeadlineEnd = event['cancelDeadlineEnd']?.toString();
      });
    }
  }

  // 서버에서 장바구니 목록 불러오기
  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _cartService.getCartItems(eventId: widget.eventId);

    if (!mounted) return;

    if (result['success'] == true) {
      final items = List<Map<String, dynamic>>.from(result['items'] ?? []);
      setState(() {
        _cartItems = items.map((item) {
          final productItem = item['productItem'] as Map<String, dynamic>?;
          final product = item['product'] as Map<String, dynamic>?;
          final rawPrice = productItem?['price'] ?? 0;
          final price = (rawPrice is num) ? rawPrice.toInt() : 0;
          // 품목별 계약금 비율 (null이면 행사 기본값 사용)
          final productDepositRate = product?['depositRate'];
          return {
            'id': item['id']?.toString() ?? '',
            'productId': item['productId']?.toString() ?? '',
            'productItemId': item['productItemId']?.toString(),
            'vendorName': product?['vendorName'] ?? '업체명 없음',
            'productName': productItem?['name'] ?? product?['name'] ?? '상품명 없음',
            'description': productItem?['description'] ?? product?['description'] ?? '',
            'price': price,
            'depositRate': productDepositRate is num ? productDepositRate.toDouble() : null,
            'imageUrl': productItem?['image'] ?? product?['image'],
            'categoryName': product?['name'] ?? '', // 1뎁스 품목명
          };
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? '장바구니를 불러올 수 없습니다';
        _isLoading = false;
      });
    }
  }

  // 전체 합계
  int get _totalPrice {
    return _cartItems.fold(0, (sum, item) => sum + ((item['price'] as num?)?.toInt() ?? 0));
  }

  // 품목별 계약금 비율 가져오기 (품목별 설정이 없으면 행사 기본값)
  double _getItemDepositRate(Map<String, dynamic> item) {
    return (item['depositRate'] as double?) ?? _defaultDepositRate;
  }

  // 계약금 (품목별 비율 적용)
  int get _depositAmount {
    return _cartItems.fold(0, (sum, item) {
      final price = (item['price'] as num?)?.toInt() ?? 0;
      final rate = _getItemDepositRate(item);
      return sum + (price * rate).round();
    });
  }

  // 잔금
  int get _remainAmount => _totalPrice - _depositAmount;


  // 취소 기간 안내 텍스트
  String get _cancelPeriodText {
    if (_cancelDeadlineStart == null || _cancelDeadlineEnd == null) return '';
    try {
      final start = DateTime.parse(_cancelDeadlineStart!);
      final end = DateTime.parse(_cancelDeadlineEnd!);
      final startStr = '${start.year}년 ${start.month.toString().padLeft(2, '0')}월 ${start.day.toString().padLeft(2, '0')}일';
      final endStr = '${end.year}년 ${end.month.toString().padLeft(2, '0')}월 ${end.day.toString().padLeft(2, '0')}일';
      return '취소는 취소기간 내에 가능합니다 [$startStr ~ $endStr까지]\n';
    } catch (_) {
      return '';
    }
  }

  // 숫자 콤마 표시
  String _formatPrice(int price) {
    return NumberFormat('#,###').format(price);
  }

  // 항목 삭제 (서버 + 로컬)
  Future<void> _removeItem(String id) async {
    setState(() {
      _cartItems.removeWhere((item) => item['id'] == id);
    });
    await _cartService.removeItem(id);
  }

  // 계약하기 → 바로 계약 API 호출 → 결제 화면으로 이동 (확인 팝업 없이 바로 진행)
  void _handleContract() {
    if (_cartItems.isEmpty) return;
    if (!_agreedToTerms) return;
    _createContractAndPay();
  }

  // 계약 API 호출 후 결제 화면으로 이동
  Future<void> _createContractAndPay() async {
    final selectedItems = _cartItems
        .map((item) => {
              'productId': item['productId'] as String,
              'eventId': widget.eventId,
              if (item['productItemId'] != null)
                'productItemId': item['productItemId'] as String,
            })
        .toList();

    setState(() => _isContractLoading = true);

    final result = await _contractService.createContracts(
      items: selectedItems,
    );

    if (!mounted) return;
    setState(() => _isContractLoading = false);

    if (result['success']) {
      final contracts = List<Map<String, dynamic>>.from(result['contracts']);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            contracts: contracts,
            eventId: widget.eventId,
            eventTitle: widget.eventTitle,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '계약 생성에 실패했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 임베디드 모드: body만 반환 (EventDetailScreen의 IndexedStack에서 사용)
    if (widget.embedded) {
      return _buildBody();
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppHeader(title: widget.eventTitle),
        body: _buildBody(),
        bottomNavigationBar: AppTabBar.customer(
          currentIndex: 1,
          onTap: (index) {
            if (index == 1) return;
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // 본문
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        message: _error!,
        actionLabel: '다시 시도',
        onAction: _loadCartItems,
      );
    }
    if (_cartItems.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_cart_outlined,
        message: '장바구니가 비어있습니다',
        subMessage: '품목 리스트에서 상품을 담아보세요',
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "장바구니 >" 부제목
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Row(
              children: [
                Text('장바구니', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
          // 장바구니 품목 카드 목록
          ...(_groupedCartItems.entries.map((entry) =>
            _buildCategoryCard(entry.key, entry.value))),
          const SizedBox(height: 24),
          // 총 견적 바
          _buildSummaryBar(),
          const SizedBox(height: 16),
          // 동의 체크박스 + 안내 문구
          _buildAgreementSection(),
          const SizedBox(height: 12),
          // 계약금 결제하기 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_agreedToTerms && !_isContractLoading) ? _handleContract : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isContractLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('계약금 결제하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('${_formatPrice(_depositAmount)}원', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1뎁스 카테고리별로 그룹핑
  Map<String, List<Map<String, dynamic>>> get _groupedCartItems {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in _cartItems) {
      final cat = item['categoryName'] as String? ?? '기타';
      grouped.putIfAbsent(cat, () => []).add(item);
    }
    return grouped;
  }

  // 1뎁스 카테고리 카드
  Widget _buildCategoryCard(String category, List<Map<String, dynamic>> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 6, 24, 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(category, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          // 품목 항목들
          ...items.map((item) => _buildCartItemCard(item)),
        ],
      ),
    );
  }

  // 개별 품목 카드 (디자인: 7.고객용-장바구니.jpg)
  Widget _buildCartItemCard(Map<String, dynamic> item) {
    final price = (item['price'] as num?)?.toInt() ?? 0;
    final rate = _getItemDepositRate(item);
    final deposit = (price * rate).round();
    final remain = price - deposit;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 업체명 + 삭제(휴지통) 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['vendorName'] ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              GestureDetector(
                onTap: () => _removeItem(item['id']),
                child: const Icon(Icons.delete_outline, size: 20, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 패키지명
          Text(
            item['productName'] ?? '',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          // 설명
          if ((item['description'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 2),
            Text(
              item['description'],
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          // 가격 / 계약금 / 잔금 (우측 정렬)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '가격 : ${_formatPrice(price)}원',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '계약금 : ${_formatPrice(deposit)}원',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.priceRed),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '잔금 : ${_formatPrice(remain)}원',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 상세보기 버튼 → 품목 상세 팝업
          OutlinedButton(
            onPressed: () => _showItemDetail(item),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('상세보기'),
          ),
        ],
      ),
    );
  }

  // 총 견적 바 (디자인: 검정 배경 카드)
  Widget _buildSummaryBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // "총 견적" 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Text(
              '총 견적',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          // 견적 내용
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Column(
              children: [
                _buildSummaryRow('계약 총액', '${_formatPrice(_totalPrice)}원'),
                const Divider(height: 20),
                _buildSummaryRow('계약금 총액', '${_formatPrice(_depositAmount)}원', valueColor: AppColors.priceRed),
                const SizedBox(height: 6),
                _buildSummaryRow('잔금 총액', '${_formatPrice(_remainAmount)}원'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 요약 행
  Widget _buildSummaryRow(String label, String value, {Color valueColor = AppColors.textPrimary}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: valueColor == AppColors.priceRed ? AppColors.priceRed : AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }

  // 장바구니 품목 상세보기 팝업
  void _showItemDetail(Map<String, dynamic> item) {
    final price = (item['price'] as num?)?.toInt() ?? 0;
    final rate = _getItemDepositRate(item);
    final deposit = (price * rate).round();
    final remain = price - deposit;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          item['productName'] ?? '품목 상세',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 업체명
            Text('업체: ${item['vendorName'] ?? '-'}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            // 카테고리
            if ((item['categoryName'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text('품목: ${item['categoryName']}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
            // 설명
            if ((item['description'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(item['description'],
                style: const TextStyle(fontSize: 13, height: 1.4)),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // 가격 정보
            _buildDetailPriceRow('가격', '${_formatPrice(price)}원'),
            const SizedBox(height: 4),
            _buildDetailPriceRow('계약금', '${_formatPrice(deposit)}원', color: AppColors.priceRed),
            const SizedBox(height: 4),
            _buildDetailPriceRow('잔금', '${_formatPrice(remain)}원'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // 상세보기 가격 행
  Widget _buildDetailPriceRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: color ?? AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary)),
      ],
    );
  }

  // 동의 체크박스 + 안내 문구 (디자인: 7.고객용-장바구니.jpg)
  Widget _buildAgreementSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 체크박스 + 동의 문구 (1줄)
          GestureDetector(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _agreedToTerms,
                    onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '계약금 먼저 결제 되며, 취소 환불 조항에 동의합니다.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          // 상세 안내 문구 (취소 기간 포함)
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 8),
            child: Text(
              '지금 결제 하시면 모두 결제되는 것이 아니라 계약금만 결제되며, 잔금은 해당 업체와 직접 결제하시면 됩니다.\n'
              '$_cancelPeriodText'
              '취소 지정 기간 이후 취소 건은 계약금 환불은 어렵습니다.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
