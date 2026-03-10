import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/contract/contract_card.dart';
import '../../widgets/common/app_card.dart';
import '../../services/contract_service.dart';
import 'home_screen.dart';
import '../customer/contract_detail_screen.dart';

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
  final int _currentTabIndex = 1;  // 계약함 탭이 선택된 상태

  // API에서 가져온 계약 목록
  List<Map<String, dynamic>> _contracts = [];
  bool _isLoading = true;
  String? _error;

  final ContractService _contractService = ContractService();

  @override
  void initState() {
    super.initState();
    _loadContracts(); // 화면 열릴 때 계약 목록 불러오기
  }

  // 서버에서 계약 목록 가져오기
  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _contractService.getVendorContracts();

    if (!mounted) return;

    if (result['success'] == true) {
      final List contracts = result['contracts'] ?? [];
      setState(() {
        _contracts = contracts.map<Map<String, dynamic>>((c) {
          final customer = c['customer'] as Map<String, dynamic>?;
          final event = c['event'] as Map<String, dynamic>?;
          return {
            'id': c['id']?.toString() ?? '',
            'customerName': c['customerName'] ?? customer?['name'] ?? '고객',
            'customerAddress': c['customerAddress'] ?? '',
            'customerDong': c['customerDong'] ?? '',
            'customerHo': c['customerHo'] ?? '',
            'customerHousingType': c['customerHousingType'] ?? '',
            'customerPhone': c['customerPhone'] ?? customer?['phone'] ?? '',
            'customerEmail': customer?['email'] ?? '',
            'productName': c['productItem']?['name'] ?? c['product']?['name'] ?? c['productItemName'] ?? c['productName'] ?? '상품명 없음',
            'productCategory': c['product']?['category'] ?? c['productName'] ?? '',
            'description': c['productItem']?['description'] ?? c['product']?['description'] ?? '',
            'price': c['originalPrice'] ?? c['price'] ?? 0,
            'originalPrice': c['originalPrice'] ?? 0,
            'depositAmount': c['depositAmount'] ?? 0,
            'remainAmount': c['remainAmount'] ?? 0,
            'status': c['status'] ?? 'CONFIRMED',
            // 행사/주관사 정보
            'eventTitle': event?['title'] ?? '',
            'siteName': event?['siteName'] ?? '',
            'organizerName': event?['organizer']?['name'] ?? '',
            // 업체 정보 (본인)
            'vendorName': c['product']?['vendorName'] ?? c['vendorName'] ?? '',
            'vendorPhone': c['product']?['vendor']?['phone'] ?? '',
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

  // 상태 파싱 (PENDING/CANCEL_REQUESTED 추가)
  ContractCardStatus _parseStatus(String status) {
    switch (status) {
      case 'CONFIRMED':
        return ContractCardStatus.confirmed;
      case 'CANCEL_REQUESTED':
        return ContractCardStatus.cancelRequested;
      case 'CANCELLED':
        return ContractCardStatus.cancelled;
      case 'PENDING':
        return ContractCardStatus.pending;
      default:
        return ContractCardStatus.confirmed;
    }
  }

  // 취소 승인 확인 다이얼로그
  void _showApproveCancelDialog(Map<String, dynamic> contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('취소 승인'),
        content: Text(
          '${contract['customerName']}의 \'${contract['productName']}\' 취소를 승인하시겠습니까?\n\n'
          '승인하면 계약이 취소되고 결제가 환불됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _approveCancel(contract);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.priceRed),
            child: const Text('승인'),
          ),
        ],
      ),
    );
  }

  // 취소 거부 확인 다이얼로그
  void _showRejectCancelDialog(Map<String, dynamic> contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('취소 거부'),
        content: Text(
          '${contract['customerName']}의 \'${contract['productName']}\' 취소 요청을 거부하시겠습니까?\n\n'
          '거부하면 계약이 유지됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectCancel(contract);
            },
            child: const Text('거부'),
          ),
        ],
      ),
    );
  }

  // 취소 승인 API 호출
  Future<void> _approveCancel(Map<String, dynamic> contract) async {
    final result = await _contractService.approveCancel(contract['id']);
    if (!mounted) return;

    if (result['success'] == true) {
      // 성공 시 목록 전체 새로고침 (서버 최신 상태 반영)
      _loadContracts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('취소가 승인되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '취소 승인에 실패했습니다')),
      );
    }
  }

  // 업체 직접 계약 취소 다이얼로그
  void _showVendorCancelDialog(Map<String, dynamic> contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('계약 취소 및 환불'),
        content: Text(
          '${contract['customerName']}님의 \'${contract['productName']}\' 계약을 취소하시겠습니까?\n\n'
          '취소 시 결제금이 환불 처리됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _vendorCancel(contract);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.priceRed),
            child: const Text('취소 및 환불'),
          ),
        ],
      ),
    );
  }

  // 업체 직접 계약 취소 API 호출
  Future<void> _vendorCancel(Map<String, dynamic> contract) async {
    final result = await _contractService.vendorCancelContract(contract['id']);
    if (!mounted) return;

    if (result['success'] == true) {
      _loadContracts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계약이 취소되었습니다. 환불이 처리됩니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '계약 취소에 실패했습니다')),
      );
    }
  }

  // 취소 거부 API 호출
  Future<void> _rejectCancel(Map<String, dynamic> contract) async {
    final result = await _contractService.rejectCancel(contract['id']);
    if (!mounted) return;

    if (result['success'] == true) {
      // 성공 시 목록 전체 새로고침
      _loadContracts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('취소 요청이 거부되었습니다. 계약이 유지됩니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '취소 거부에 실패했습니다')),
      );
    }
  }

  // 집계 데이터 — 실제 API 데이터 기반 계산
  int get _totalCount => _contracts.where((c) => c['status'] != 'CANCELLED').length;
  int get _cancelCount => _contracts.where((c) =>
      c['status'] == 'CANCELLED' || c['status'] == 'CANCEL_REQUESTED').length;
  int get _totalAmount {
    return _contracts
        .where((c) => c['status'] != 'CANCELLED')
        .fold(0, (sum, c) => sum + ((c['price'] as num?)?.toInt() ?? 0));
  }

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
          MaterialPageRoute(builder: (_) => const VendorHomeScreen()),
        );
        break;
      case 1: // 계약함 — 현재 화면이므로 무시
        break;
      case 2: // 마이페이지
        context.push(AppRoutes.mypage, extra: 'VENDOR');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppHeader(title: '계약함'),
      body: _buildBody(),
      // 하단 탭바 (업체용 3탭)
      bottomNavigationBar: AppTabBar.vendor(
        currentIndex: _currentTabIndex,
        onTap: _onTabChanged,
      ),
    );
  }

  // 본문: 로딩 / 에러 / 계약 목록 분기
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
            TextButton(onPressed: _loadContracts, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_contracts.isEmpty) return _buildEmptyState();

    return Column(
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
                  // 계약 상세 화면으로 이동
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CustomerContractDetailScreen(
                        contract: contract,
                        categoryName: contract['productCategory'] ?? '계약 상세',
                      ),
                    ),
                  );
                },
                // 확정/대기 상태일 때 업체 직접 취소 버튼 표시
                onVendorCancelTap: (contract['status'] == 'CONFIRMED' || contract['status'] == 'PENDING')
                    ? () => _showVendorCancelDialog(contract)
                    : null,
                // 취소 요청 상태일 때 승인/거부 버튼 표시
                onApproveTap: contract['status'] == 'CANCEL_REQUESTED'
                    ? () => _showApproveCancelDialog(contract)
                    : null,
                onRejectTap: contract['status'] == 'CANCEL_REQUESTED'
                    ? () => _showRejectCancelDialog(contract)
                    : null,
              );
            },
          ),
        ),
      ],
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
