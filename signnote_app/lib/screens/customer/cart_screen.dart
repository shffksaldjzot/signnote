import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../services/cart_service.dart';
import '../../services/contract_service.dart';
import '../../services/event_service.dart';
import 'payment_screen.dart';

// ============================================
// 장바구니 화면
//
// 디자인 참고: 7.고객용-장바구니.jpg
// - 상단: ← "장바구니" 헤더
// - 장바구니 항목 리스트 (서버에서 불러옴)
// - 할인/합계 요약 바
// - 하단: "계약하기" 버튼
// ============================================

class CartScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const CartScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final ContractService _contractService = ContractService();
  final EventService _eventService = EventService();

  // 장바구니 항목 목록 (서버에서 불러옴)
  List<Map<String, dynamic>> _cartItems = [];
  final Set<String> _selectedIds = {};
  bool _selectAll = true;
  bool _isLoading = true;
  bool _isContractLoading = false;
  String? _error;
  double _depositRate = AppConstants.depositRate; // 행사별 계약금 비율

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
      if (rate != null) {
        setState(() => _depositRate = (rate as num).toDouble());
      }
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
          // 2뎁스 상세품목(productItem)이 있으면 거기서 가격/이름 가져오기
          final productItem = item['productItem'] as Map<String, dynamic>?;
          final product = item['product'] as Map<String, dynamic>?;
          // 가격: productItem 가격 우선, 없으면 0 (Product 모델에는 price 없음)
          final rawPrice = productItem?['price'] ?? 0;
          final price = (rawPrice is num) ? rawPrice.toInt() : 0;
          return {
            'id': item['id']?.toString() ?? '',
            'productId': item['productId']?.toString() ?? '',
            'productItemId': item['productItemId']?.toString(),
            'vendorName': product?['vendorName'] ?? '업체명 없음',
            'productName': productItem?['name'] ?? product?['name'] ?? '상품명 없음',
            'description': productItem?['description'] ?? product?['description'] ?? '',
            'price': price,
            'imageUrl': productItem?['image'] ?? product?['image'],
            'categoryName': product?['name'] ?? '',  // 1뎁스 품목명
          };
        }).toList();
        // 처음엔 모두 선택
        _selectedIds.addAll(_cartItems.map((e) => e['id'] as String));
        _selectAll = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? '장바구니를 불러올 수 없습니다';
        _isLoading = false;
      });
    }
  }

  // 선택된 상품들의 합계 계산
  int get _totalPrice {
    return _cartItems
        .where((item) => _selectedIds.contains(item['id']))
        .fold(0, (sum, item) => sum + ((item['price'] as num?)?.toInt() ?? 0));
  }

  // 계약금 (행사별 비율 적용)
  int get _depositAmount {
    return (_totalPrice * _depositRate).round();
  }

  // 계약금 비율 퍼센트 표시
  int get _depositPercent => (_depositRate * 100).round();

  // 숫자를 콤마 표시
  String _formatPrice(int price) {
    return NumberFormat('#,###').format(price);
  }

  // 전체 선택/해제
  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedIds.addAll(_cartItems.map((e) => e['id'] as String));
      } else {
        _selectedIds.clear();
      }
    });
  }

  // 개별 선택/해제
  void _toggleItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _selectAll = _selectedIds.length == _cartItems.length;
    });
  }

  // 항목 삭제 (서버 + 로컬)
  Future<void> _removeItem(String id) async {
    // 로컬 먼저 반영 (빠른 응답)
    setState(() {
      _cartItems.removeWhere((item) => item['id'] == id);
      _selectedIds.remove(id);
      _selectAll = _selectedIds.length == _cartItems.length && _cartItems.isNotEmpty;
    });
    // 서버에서도 삭제
    await _cartService.removeItem(id);
  }

  // 계약하기 → 계약 API 호출 → 결제 화면으로 이동
  void _handleContract() {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계약할 상품을 선택해 주세요')),
      );
      return;
    }

    // 계약 확인 다이얼로그
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '계약하시겠습니까?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('선택 품목: ${_selectedIds.length}개'),
            const SizedBox(height: 4),
            Text('합계: ${_formatPrice(_totalPrice)}원'),
            const SizedBox(height: 4),
            Text(
              '계약금($_depositPercent%): ${_formatPrice(_depositAmount)}원',
              style: const TextStyle(
                color: AppColors.priceRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '계약 후 계약금 결제가 진행됩니다.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _createContractAndPay();
            },
            child: const Text(
              '계약하기',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 계약 API 호출 후 결제 화면으로 이동
  Future<void> _createContractAndPay() async {
    final selectedItems = _cartItems
        .where((item) => _selectedIds.contains(item['id']))
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

    setState(() => _isContractLoading = false);

    if (!mounted) return;

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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(title: '장바구니'),
      body: _buildBody(),
    );
  }

  // 본문: 로딩 / 에러 / 비어있음 / 목록
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

    return Column(
      children: [
        // 전체 선택 체크박스
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Row(
            children: [
              Checkbox(
                value: _selectAll,
                onChanged: _toggleSelectAll,
                activeColor: AppColors.primary,
              ),
              Text(
                '전체 선택 (${_selectedIds.length}/${_cartItems.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 장바구니 항목 리스트
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: _cartItems.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              return _buildCartItem(item);
            },
          ),
        ),
        // 합계 요약 바
        _buildSummaryBar(),
        // 계약하기 버튼
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: AppButton(
            text: '계약하기',
            enabled: _selectedIds.isNotEmpty,
            isLoading: _isContractLoading,
            onPressed: _handleContract,
          ),
        ),
      ],
    );
  }

  // 장바구니 항목 1개
  Widget _buildCartItem(Map<String, dynamic> item) {
    final isSelected = _selectedIds.contains(item['id']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: isSelected,
          onChanged: (_) => _toggleItem(item['id']),
          activeColor: AppColors.primary,
        ),
        // 상품 이미지
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 72,
            height: 72,
            color: AppColors.background,
            child: item['imageUrl'] != null
                ? Image.network(item['imageUrl'], fit: BoxFit.cover)
                : const Icon(Icons.image_outlined, color: AppColors.textHint),
          ),
        ),
        const SizedBox(width: 12),
        // 상품 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['vendorName'],
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                item['productName'],
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatPrice(item['price'])}원',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.priceRed,
                ),
              ),
            ],
          ),
        ),
        // 삭제 버튼
        GestureDetector(
          onTap: () => _removeItem(item['id']),
          child: const Icon(Icons.close, size: 20, color: AppColors.textHint),
        ),
      ],
    );
  }

  // 합계 요약 바
  Widget _buildSummaryBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AppCard.dark(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow('품목가', '${_formatPrice(_totalPrice)}원'),
            const Divider(height: 16, color: Colors.white24),
            _buildSummaryRow('합계', '${_formatPrice(_totalPrice)}원', isBold: true),
            const SizedBox(height: 4),
            _buildSummaryRow(
              '계약금($_depositPercent%)',
              '${_formatPrice(_depositAmount)}원',
              valueColor: AppColors.priceRed,
            ),
          ],
        ),
      ),
    );
  }

  // 요약 행
  Widget _buildSummaryRow(String label, String value, {
    bool isBold = false,
    Color valueColor = Colors.white,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
