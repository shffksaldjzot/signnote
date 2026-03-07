import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../services/contract_service.dart';
import 'home_screen.dart';
import 'contract_detail_screen.dart';

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
            'vendorName': c['product']?['vendorName'] ?? vendor?['name'] ?? '업체명 없음',
            'vendorPhone': vendor?['phone'] ?? '',
            'vendorRepresentative': vendor?['representativeName'] ?? '',
            'vendorBusinessNumber': vendor?['businessNumber'] ?? '',
            'vendorBusinessAddress': vendor?['businessAddress'] ?? '',
            'productName': c['productItem']?['name'] ?? c['product']?['name'] ?? c['productName'] ?? '상품명 없음',
            'productCategory': c['product']?['category'] ?? c['productCategory'] ?? '기타',
            'description': c['productItem']?['description'] ?? c['product']?['description'] ?? '',
            'originalPrice': c['originalPrice'] ?? 0,
            'price': c['originalPrice'] ?? 0,
            'depositAmount': c['depositAmount'] ?? 0,
            'remainAmount': c['remainAmount'] ?? 0,
            'status': c['status'] ?? 'PENDING',
            // 행사/주관사 정보
            'eventTitle': event?['title'] ?? '',
            'siteName': event?['siteName'] ?? '',
            'organizerName': event?['organizer']?['name'] ?? '',
            // 고객 정보 (본인)
            'customerName': c['customerName'] ?? '',
            'customerPhone': c['customerPhone'] ?? '',
            'customerAddress': c['customerAddress'] ?? '',
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
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        );
        break;
      case 1: // 장바구니 — 행사 ID 필요
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('홈에서 장바구니를 이용해 주세요')),
        );
        break;
      case 2: break;
      case 3:
        context.push(AppRoutes.mypage, extra: 'CUSTOMER');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('계약함', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('각 계약의 상세보기에서 개별 다운로드를 이용해 주세요')),
                );
              },
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
