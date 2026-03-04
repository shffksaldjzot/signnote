import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/contract/contract_card.dart';
import '../../services/contract_service.dart';

// ============================================
// 고객용 계약함 화면
//
// 디자인 참고: 8.고객용-계약함.jpg
// - 상단: ← "계약함" 헤더
// - 계약 카드 목록
//   - 각 카드: 상태 뱃지 + 업체명 + 상품명 + 설명 + 가격/계약금/잔금
//   - 상태: 계약금 결제 완료(검정), 취소 요청(빨강), 취소 완료(회색)
// - 하단 요약 바: 총 계약 금액 + 총 계약금 + 총 잔금
// - 하단: 4탭 네비게이션
// ============================================

class CustomerContractScreen extends StatefulWidget {
  const CustomerContractScreen({super.key});

  @override
  State<CustomerContractScreen> createState() => _CustomerContractScreenState();
}

class _CustomerContractScreenState extends State<CustomerContractScreen> {
  int _currentTabIndex = 2;  // 계약함 탭이 선택된 상태

  // TODO: API에서 계약 목록 가져오기 (현재 임시 데이터)
  final List<Map<String, dynamic>> _contracts = [
    {
      'id': '1',
      'vendorName': '앤드 디자인',
      'productName': '줄눈 B 패키지',
      'description': 'A패키지 + 욕실 전체벽',
      'price': 1400000,
      'depositAmount': 420000,
      'status': 'CONFIRMED',
    },
    {
      'id': '2',
      'vendorName': '워터바이',
      'productName': '나노코팅 A 패키지',
      'description': '(욕실)거울2+세면대2+변기2+샤워부스1\n(주방)싱크대 상판',
      'price': 700000,
      'depositAmount': 210000,
      'status': 'CONFIRMED',
    },
    {
      'id': '3',
      'vendorName': '앤드 디자인',
      'productName': '줄눈 A 패키지',
      'description': '욕실2바닥+현관+안방샤워부스 벽면1곳\n+다용도실',
      'price': 700000,
      'depositAmount': 210000,
      'status': 'CANCELLED',
    },
  ];

  final ContractService _contractService = ContractService();

  // 상태 문자열 → ContractCardStatus 변환
  // PENDING = 결제 대기, CONFIRMED = 결제 완료, CANCEL_REQUESTED = 취소 요청, CANCELLED = 취소
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
      // 로컬 상태 업데이트 (서버 재조회 없이 바로 반영)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppHeader(title: '계약함'),
      body: _contracts.isEmpty
          ? _buildEmptyState()
          : Column(
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
                        onDetailTap: () {
                          // TODO: 계약 상세 화면으로 이동
                        },
                        // 확정 상태일 때만 취소 요청 가능
                        onCancelTap: contract['status'] == 'CONFIRMED'
                            ? () => _showCancelRequestDialog(contract)
                            : null,
                      );
                    },
                  ),
                ),
                // 하단 합계 요약 바
                _buildSummaryBar(),
              ],
            ),
      // 하단 탭바
      bottomNavigationBar: AppTabBar.customer(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
          // TODO: 탭별 화면 이동
        },
      ),
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

  // 빈 상태
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 48, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            '계약 내역이 없습니다',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
