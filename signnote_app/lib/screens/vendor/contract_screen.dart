import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/contract/contract_card.dart';
import '../../widgets/common/app_card.dart';
import '../../services/contract_service.dart';
import '../../utils/image_download.dart';
import 'home_screen.dart';
import '../customer/contract_detail_screen.dart';

// ============================================
// 업체용 계약함 화면
//
// 디자인 참고: 10.업체용-계약함.jpg, 11.업체용-계약함 상세.jpg
// - 상단: ← "계약함" 헤더 + 돋보기(검색) 아이콘
// - 상태 필터 칩 (전체/계약/취소요청/취소)
// - 집계 요약 카드 (총 계약건수, 총 금액, 취소건수)
// - 계약 카드 목록
// - 하단: 탭 네비게이션
// ============================================

class VendorContractScreen extends StatefulWidget {
  const VendorContractScreen({super.key});

  @override
  State<VendorContractScreen> createState() => _VendorContractScreenState();
}

class _VendorContractScreenState extends State<VendorContractScreen> {
  final int _currentTabIndex = 1; // 계약함 탭이 선택된 상태

  // API에서 가져온 계약 목록
  List<Map<String, dynamic>> _contracts = [];
  bool _isLoading = true;
  String? _error;

  // 검색 기능
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 상태 필터 (null = 전체)
  String? _statusFilter;

  // 선택 다운로드용 체크 상태
  final Set<String> _selectedIds = {};

  final ContractService _contractService = ContractService();

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  // 필터 + 검색 적용된 계약 목록
  List<Map<String, dynamic>> get _filteredContracts {
    var list = _contracts;

    // 상태 필터 적용
    if (_statusFilter != null) {
      if (_statusFilter == 'ACTIVE') {
        // 계약건 = CONFIRMED + PENDING
        list = list.where((c) =>
          c['status'] == 'CONFIRMED' || c['status'] == 'PENDING').toList();
      } else {
        list = list.where((c) => c['status'] == _statusFilter).toList();
      }
    }

    // 검색어 필터 적용 (고객명, 품목명으로 검색)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        final name = (c['customerName'] as String? ?? '').toLowerCase();
        final product = (c['productName'] as String? ?? '').toLowerCase();
        final phone = (c['customerPhone'] as String? ?? '').toLowerCase();
        return name.contains(q) || product.contains(q) || phone.contains(q);
      }).toList();
    }

    return list;
  }

  // 상태 파싱
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

  // 집계 데이터 — 전체 데이터 기준 (필터 무관)
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
      case 1: break; // 현재
      case 2: // 마이페이지
        context.push(AppRoutes.mypage, extra: 'VENDOR');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(
        title: '계약함',
        actions: [
          // 돋보기 검색 버튼
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: AppTabBar.vendor(
        currentIndex: _currentTabIndex,
        onTap: _onTabChanged,
      ),
    );
  }

  // 본문
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

    final filtered = _filteredContracts;

    // 전체 선택 여부
    final allSelected = filtered.isNotEmpty && filtered.every((c) => _selectedIds.contains(c['id']));

    return Column(
      children: [
        // 검색창 (돋보기 클릭 시 노출)
        if (_showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '고객명, 품목명, 연락처 검색',
                hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.textPrimary),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        // 상태 필터 칩
        _buildFilterChips(),
        // 집계 요약 카드
        _buildSummaryCards(),
        // 전체 선택 체크박스
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Row(
            children: [
              SizedBox(
                width: 20, height: 20,
                child: Checkbox(
                  value: allSelected,
                  onChanged: (_) {
                    setState(() {
                      if (allSelected) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(filtered.map((c) => c['id'] as String));
                      }
                    });
                  },
                  activeColor: AppColors.vendor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
              const Text('전체 선택', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              // 선택 건수 표시
              if (_selectedIds.isNotEmpty)
                Text('${_selectedIds.length}건 선택', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        // 계약 카드 목록 (필터 적용)
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('검색 결과가 없습니다', style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contract = filtered[index];
                    final contractId = contract['id'] as String;
                    final isSelected = _selectedIds.contains(contractId);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 체크박스
                        Padding(
                          padding: const EdgeInsets.only(top: 16, right: 8),
                          child: SizedBox(
                            width: 20, height: 20,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedIds.add(contractId);
                                  } else {
                                    _selectedIds.remove(contractId);
                                  }
                                });
                              },
                              activeColor: AppColors.vendor,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        // 계약 카드
                        Expanded(
                          child: ContractCard.vendor(
                            customerName: contract['customerName'],
                            customerAddress: contract['customerAddress'],
                            customerPhone: contract['customerPhone'],
                            productName: contract['productName'],
                            productDescription: contract['description'],
                            price: contract['price'],
                            depositAmount: contract['depositAmount'],
                            status: _parseStatus(contract['status']),
                            onDetailTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CustomerContractDetailScreen(
                                    contract: contract,
                                    categoryName: contract['productCategory'] ?? '계약 상세',
                                  ),
                                ),
                              );
                            },
                            onVendorCancelTap: (contract['status'] == 'CONFIRMED' || contract['status'] == 'PENDING')
                                ? () => _showVendorCancelDialog(contract)
                                : null,
                            onApproveTap: contract['status'] == 'CANCEL_REQUESTED'
                                ? () => _showApproveCancelDialog(contract)
                                : null,
                            onRejectTap: contract['status'] == 'CANCEL_REQUESTED'
                                ? () => _showRejectCancelDialog(contract)
                                : null,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        // 하단: 선택 다운로드 버튼 (선택 없으면 비활성화)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedIds.isEmpty ? null : _downloadSelectedContracts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vendor,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textHint,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: Text(_selectedIds.isEmpty
                  ? '계약서 다운로드 (선택해 주세요)'
                  : '선택 계약서 다운로드 (${_selectedIds.length}건)'),
            ),
          ),
        ),
      ],
    );
  }

  // 상태 필터 칩 (전체 / 계약건 / 취소요청 / 취소)
  Widget _buildFilterChips() {
    final filters = <Map<String, String?>>[
      {'label': '전체', 'value': null},
      {'label': '계약건', 'value': 'ACTIVE'},
      {'label': '취소요청', 'value': 'CANCEL_REQUESTED'},
      {'label': '취소', 'value': 'CANCELLED'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        children: filters.map((f) {
          final isSelected = _statusFilter == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                f['label']!,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.textPrimary,
              backgroundColor: AppColors.background,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (_) {
                setState(() => _statusFilter = f['value']);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // 집계 요약 카드
  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
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
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }

  // 선택한 계약서 다운로드 (이미지 파일로 순차 다운로드)
  Future<void> _downloadSelectedContracts() async {
    if (_selectedIds.isEmpty) return;
    final selected = _contracts.where((c) => _selectedIds.contains(c['id'])).toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${selected.length}건의 계약서를 다운로드합니다...')),
    );

    int downloadCount = 0;
    for (final contract in selected) {
      final success = await _downloadContractAsImage(contract);
      if (success) downloadCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$downloadCount건의 계약서가 다운로드되었습니다')),
      );
    }
  }

  // 개별 계약을 이미지로 다운로드 (오프스크린 렌더링 — 고객 계약서와 동일 형식)
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
                child: CustomerContractDetailScreen.buildContractContent(contract),
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

  // 빈 상태
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 48, color: AppColors.textHint),
          SizedBox(height: 12),
          Text('계약 내역이 없습니다', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
