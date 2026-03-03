import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/contract/contract_card.dart';
import '../../widgets/common/app_card.dart';

// ============================================
// 업체용 계약함 화면
//
// 디자인 참고: 10.업체용-계약함.jpg, 11.업체용-계약함 상세.jpg
// - 상단: ← "계약함" 헤더
// - 집계 요약 카드 (총 계약건수, 총 금액, 취소건수)
// - 계약 카드 목록
//   - 각 카드: 고객 정보(동/호수/이름/전화) + 상품명 + 상태 뱃지 + 가격
// - 하단: 3탭 네비게이션
// ============================================

class VendorContractScreen extends StatefulWidget {
  const VendorContractScreen({super.key});

  @override
  State<VendorContractScreen> createState() => _VendorContractScreenState();
}

class _VendorContractScreenState extends State<VendorContractScreen> {
  int _currentTabIndex = 1;  // 계약함 탭이 선택된 상태

  // TODO: API에서 계약 목록 가져오기 (현재 임시 데이터)
  final List<Map<String, dynamic>> _contracts = [
    {
      'id': '1',
      'customerName': '김아무개 님',
      'customerAddress': '창원 자이 201동 1305호',
      'customerPhone': '010-1234-1234',
      'productName': '줄눈 B 패키지',
      'description': 'A패키지 + 욕실 전체벽',
      'price': 1400000,
      'depositAmount': 420000,
      'status': 'CONFIRMED',
    },
    {
      'id': '2',
      'customerName': '박아무개 님',
      'customerAddress': '창원 자이 101동 805호',
      'customerPhone': '010-5678-5678',
      'productName': '줄눈 A 패키지',
      'description': '욕실2바닥+현관+안방샤워부스 벽면1곳\n+다용도실',
      'price': 700000,
      'depositAmount': 210000,
      'status': 'CONFIRMED',
    },
    {
      'id': '3',
      'customerName': '이아무개 님',
      'customerAddress': '창원 자이 301동 1201호',
      'customerPhone': '010-9999-8888',
      'productName': '줄눈 B 패키지',
      'description': 'A패키지 + 욕실 전체벽',
      'price': 1400000,
      'depositAmount': 420000,
      'status': 'CANCELLED',
    },
  ];

  ContractCardStatus _parseStatus(String status) {
    switch (status) {
      case 'CONFIRMED':
        return ContractCardStatus.confirmed;
      case 'CANCELLED':
        return ContractCardStatus.cancelled;
      default:
        return ContractCardStatus.confirmed;
    }
  }

  // 집계 데이터
  int get _totalCount => _contracts.where((c) => c['status'] != 'CANCELLED').length;
  int get _cancelCount => _contracts.where((c) => c['status'] == 'CANCELLED').length;
  int get _totalAmount {
    return _contracts
        .where((c) => c['status'] != 'CANCELLED')
        .fold(0, (sum, c) => sum + (c['price'] as int));
  }

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
                // 집계 요약 카드
                _buildSummaryCards(),
                // 계약 카드 목록
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _contracts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final contract = _contracts[index];
                      return ContractCard.vendor(
                        customerName: contract['customerName'],
                        customerAddress: contract['customerAddress'],
                        customerPhone: contract['customerPhone'],
                        productName: contract['productName'],
                        productDescription: contract['description'],
                        price: contract['price'],
                        depositAmount: contract['depositAmount'],
                        status: _parseStatus(contract['status']),
                        onDetailTap: () {
                          // TODO: 계약 상세 화면으로 이동
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      // 하단 탭바 (업체용 3탭)
      bottomNavigationBar: AppTabBar.vendor(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
          // TODO: 탭별 화면 이동
        },
      ),
    );
  }

  // 집계 요약 카드 (어두운 바)
  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: AppCard.dark(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('총 계약', '$_totalCount건'),
          Container(width: 1, height: 32, color: Colors.white24),
          _buildStatItem('총 금액', '${_formatPrice(_totalAmount)}원'),
          Container(width: 1, height: 32, color: Colors.white24),
          _buildStatItem('취소', '$_cancelCount건',
              valueColor: _cancelCount > 0 ? AppColors.priceRed : Colors.white),
        ],
      ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color valueColor = Colors.white}) {
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
            fontSize: 15,
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
