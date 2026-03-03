import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';

// ============================================
// 장바구니 화면
//
// 디자인 참고: 7.고객용-장바구니.jpg
// - 상단: ← "장바구니" 헤더
// - 장바구니 항목 리스트
//   - 각 항목: 체크박스 + 상품 이미지 + 업체명 + 상품명 + 가격 + 삭제(X)
// - 할인/합계 요약 바 (어두운 카드)
//   - 품목가: xxx원, 할인금액: -xxx원, 합계: xxx원
// - 하단: "계약하기" 버튼 (선택한 상품 계약)
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
  // 선택된 항목들 (체크박스)
  final Set<String> _selectedIds = {};
  bool _selectAll = true;

  // TODO: API에서 장바구니 목록 가져오기 (현재 임시 데이터)
  final List<Map<String, dynamic>> _cartItems = [
    {
      'id': 'cart1',
      'productId': '1',
      'vendorName': '앤드 디자인',
      'productName': '줄눈 A 패키지',
      'description': '욕실2바닥+현관+안방샤워부스 벽면1곳\n+다용도실',
      'price': 700000,
      'imageUrl': null,
    },
    {
      'id': 'cart2',
      'productId': '2',
      'vendorName': '앤드 디자인',
      'productName': '줄눈 B 패키지',
      'description': 'A패키지 + 욕실 전체벽',
      'price': 1400000,
      'imageUrl': null,
    },
    {
      'id': 'cart3',
      'productId': '3',
      'vendorName': '워터바이',
      'productName': '나노코팅 A 패키지',
      'description': '(욕실)거울2+세면대2+변기2+샤워부스1',
      'price': 700000,
      'imageUrl': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    // 처음엔 모두 선택
    _selectedIds.addAll(_cartItems.map((e) => e['id'] as String));
  }

  // 선택된 상품들의 합계 계산
  int get _totalPrice {
    return _cartItems
        .where((item) => _selectedIds.contains(item['id']))
        .fold(0, (sum, item) => sum + (item['price'] as int));
  }

  // 계약금 (30%)
  int get _depositAmount {
    return (_totalPrice * AppConstants.depositRate).round();
  }

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

  // 항목 삭제
  void _removeItem(String id) {
    setState(() {
      _cartItems.removeWhere((item) => item['id'] == id);
      _selectedIds.remove(id);
      _selectAll = _selectedIds.length == _cartItems.length && _cartItems.isNotEmpty;
    });
    // TODO: API 호출로 서버에서도 삭제
  }

  // 계약하기
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
      builder: (context) => AlertDialog(
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
              '계약금(30%): ${_formatPrice(_depositAmount)}원',
              style: const TextStyle(
                color: AppColors.priceRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '계약 후 계약금 결제가 필요합니다.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 계약 API 호출
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('계약이 생성되었습니다')),
              );
              Navigator.of(context).pop(true);  // 장바구니 화면 닫기
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(title: '장바구니'),
      body: _cartItems.isEmpty
          ? _buildEmptyState()
          : Column(
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
                    onPressed: _handleContract,
                  ),
                ),
              ],
            ),
    );
  }

  // 장바구니 항목 1개
  Widget _buildCartItem(Map<String, dynamic> item) {
    final isSelected = _selectedIds.contains(item['id']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 체크박스
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
              // 업체명
              Text(
                item['vendorName'],
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              // 상품명
              Text(
                item['productName'],
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              // 가격
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

  // 합계 요약 바 (어두운 카드)
  Widget _buildSummaryBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AppCard.dark(
        padding: const EdgeInsets.all(16),
        child: Column(
        children: [
          _buildSummaryRow('품목가', '${_formatPrice(_totalPrice)}원'),
          const SizedBox(height: 6),
          _buildSummaryRow('할인금액', '0원'),  // TODO: 할인 로직 추가
          const Divider(height: 16, color: Colors.white24),
          _buildSummaryRow('합계', '${_formatPrice(_totalPrice)}원', isBold: true),
          const SizedBox(height: 4),
          _buildSummaryRow(
            '계약금(30%)',
            '${_formatPrice(_depositAmount)}원',
            valueColor: AppColors.priceRed,
          ),
        ],
      ),
      ),
    );
  }

  // 요약 행 (왼쪽 라벨 + 오른쪽 값)
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

  // 장바구니가 비었을 때
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            '장바구니가 비어있습니다',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          SizedBox(height: 4),
          Text(
            '품목 리스트에서 상품을 담아보세요',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
