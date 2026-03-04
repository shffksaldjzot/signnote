import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/contract/contract_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../services/contract_service.dart';
import 'home_screen.dart';

// ============================================
// 고객용 계약함 화면
//
// 디자인 참고: 8.고객용-계약함.jpg
// - 상단: ← "계약함" 헤더
// - 계약 카드 목록 (서버에서 불러옴)
// - 하단 합계 요약 바 + 4탭 네비게이션
// ============================================

class CustomerContractScreen extends StatefulWidget {
  const CustomerContractScreen({super.key});

  @override
  State<CustomerContractScreen> createState() => _CustomerContractScreenState();
}

class _CustomerContractScreenState extends State<CustomerContractScreen> {
  final int _currentTabIndex = 2; // 계약함 탭이 선택된 상태

  // 서버에서 불러온 계약 목록
  List<Map<String, dynamic>> _contracts = [];
  bool _isLoading = true;
  String? _error;

  final ContractService _contractService = ContractService();

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  // 서버에서 내 계약 목록 불러오기
  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _contractService.getMyContracts();

    if (!mounted) return;

    if (result['success'] == true) {
      final contracts = List<Map<String, dynamic>>.from(result['contracts'] ?? []);
      setState(() {
        _contracts = contracts.map((c) {
          return {
            'id': c['id']?.toString() ?? '',
            'vendorName': c['product']?['vendorName'] ?? c['vendorName'] ?? '업체명 없음',
            'productName': c['product']?['name'] ?? c['productName'] ?? '상품명 없음',
            'description': c['product']?['description'] ?? '',
            'price': c['finalPrice'] ?? c['originalPrice'] ?? 0,
            'depositAmount': c['depositAmount'] ?? ((c['finalPrice'] ?? 0) * 0.3).round(),
            'status': c['status'] ?? 'PENDING',
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

  // 상태 문자열 → ContractCardStatus 변환
  ContractCardStatus _parseStatus(String status) {
    switch (status) {
      case 'CONFIRMED':
        return ContractCardStatus.confirmed;
      case 'CANCEL_REQUESTED':
        return ContractCardStatus.cancelRequested;
      case 'CANCELLED':
        return ContractCardStatus.cancelled;
      case 'PENDING':
      default:
        return ContractCardStatus.pending;
    }
  }

  // 취소 요청 확인 다이얼로그
  void _showCancelRequestDialog(Map<String, dynamic> contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('취소 요청'),
        content: Text(
          '\'${contract['productName']}\' 계약을 취소 요청하시겠습니까?\n\n'
          '업체가 승인하면 취소가 완료됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestCancel(contract);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.priceRed),
            child: const Text('취소 요청'),
          ),
        ],
      ),
    );
  }

  // 취소 요청 API 호출
  Future<void> _requestCancel(Map<String, dynamic> contract) async {
    final result = await _contractService.cancelContract(contract['id']);
    if (!mounted) return;

    if (result['success']) {
      setState(() {
        contract['status'] = 'CANCEL_REQUESTED';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('취소 요청이 완료되었습니다. 업체 승인을 기다려주세요.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '취소 요청에 실패했습니다')),
      );
    }
  }

  // 활성 계약만 (취소 제외) 합계 계산
  int get _totalPrice {
    return _contracts
        .where((c) => c['status'] != 'CANCELLED')
        .fold(0, (sum, c) => sum + (c['price'] as int));
  }

  int get _totalDeposit {
    return _contracts
        .where((c) => c['status'] != 'CANCELLED')
        .fold(0, (sum, c) => sum + (c['depositAmount'] as int));
  }

  int get _totalRemain => _totalPrice - _totalDeposit;

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  // 탭 클릭 시 화면 이동
  void _onTabChanged(int index) {
    if (index == _currentTabIndex) return;

    switch (index) {
      case 0: // 홈
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        );
        break;
      case 1: // 장바구니
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('행사를 선택한 후 장바구니를 이용해 주세요')),
        );
        break;
      case 2: // 계약함 — 현재 화면
        break;
      case 3: // 마이페이지
        context.push(AppRoutes.mypage, extra: 'CUSTOMER');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppHeader(title: '계약함'),
      body: _buildBody(),
      // 하단 탭바
      bottomNavigationBar: AppTabBar.customer(
        currentIndex: _currentTabIndex,
        onTap: _onTabChanged,
      ),
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
        onAction: _loadContracts,
      );
    }
    if (_contracts.isEmpty) {
      return const EmptyState(
        icon: Icons.description_outlined,
        message: '계약 내역이 없습니다',
        subMessage: '행사에서 품목을 선택하고 계약해보세요',
      );
    }

    return Column(
      children: [
        // 계약 카드 목록
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: _contracts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final contract = _contracts[index];
              return ContractCard.customer(
                vendorName: contract['vendorName'],
                productName: contract['productName'],
                productDescription: contract['description'],
                price: contract['price'],
                depositAmount: contract['depositAmount'],
                status: _parseStatus(contract['status']),
                // 확정 상태일 때만 취소 요청 가능
                onCancelTap: contract['status'] == 'CONFIRMED'
                    ? () => _showCancelRequestDialog(contract)
                    : null,
              );
            },
          ),
        ),
        // 하단 합계 요약 바
        if (_contracts.isNotEmpty) _buildSummaryBar(),
      ],
    );
  }

  // 합계 요약 바
  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('총 계약 금액', '${_formatPrice(_totalPrice)}원'),
          Container(width: 1, height: 32, color: Colors.white24),
          _buildSummaryItem('총 계약금', '${_formatPrice(_totalDeposit)}원',
              valueColor: AppColors.priceRed),
          Container(width: 1, height: 32, color: Colors.white24),
          _buildSummaryItem('총 잔금', '${_formatPrice(_totalRemain)}원'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color valueColor = Colors.white}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
