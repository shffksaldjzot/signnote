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
import '../../widgets/common/skeleton_loading.dart';
import '../../widgets/common/animated_list_item.dart';
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
  final bool embedded; // true이면 body만 반환
  const CustomerContractScreen({super.key, this.embedded = false});

  @override
  State<CustomerContractScreen> createState() => _CustomerContractScreenState();
}

class _CustomerContractScreenState extends State<CustomerContractScreen> {
  final int _currentTabIndex = 2;

  List<Map<String, dynamic>> _contracts = [];
  bool _isLoading = true;
  String? _error;

  // 선택 다운로드용 체크 상태 (contractId → 선택 여부)
  final Set<String> _selectedIds = {};

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
    // 임베디드 모드: body만 반환 (EventDetailScreen의 IndexedStack에서 사용)
    if (widget.embedded) {
      return _buildBody();
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(
        title: _contracts.isNotEmpty
            ? _contracts.first['eventTitle']?.toString() ?? '계약함'
            : '계약함',
        showBackButton: false,
      ),
      body: _buildBody(),
      bottomNavigationBar: AppTabBar.customer(
        currentIndex: _currentTabIndex,
        onTap: _onTabChanged,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const SkeletonList(itemCount: 3); // 로딩 중 스켈레톤 표시
    if (_error != null) {
      return EmptyState(icon: Icons.error_outline, message: _error!, actionLabel: '다시 시도', onAction: _loadContracts);
    }
    if (_contracts.isEmpty) {
      return const EmptyState(icon: Icons.description_outlined, message: '계약 내역이 없습니다', subMessage: '행사에서 품목을 선택하고 계약해보세요');
    }

    final grouped = _groupedContracts;

    // 전체 선택 여부
    final allSelected = _contracts.isNotEmpty && _selectedIds.length == _contracts.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // 계약함 헤더 + 전체 선택 체크박스
              Row(
                children: [
                  const Text('계약함', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 20),
                  const Spacer(),
                  // 전체 선택 체크박스
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (allSelected) {
                          _selectedIds.clear();
                        } else {
                          _selectedIds.addAll(_contracts.map((c) => c['id'] as String));
                        }
                      });
                    },
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
                                  _selectedIds.addAll(_contracts.map((c) => c['id'] as String));
                                }
                              });
                            },
                            activeColor: AppColors.primary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('전체 선택', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 카테고리별 그룹핑 (순차 등장 애니메이션 적용)
              ...() {
                int animIndex = 0; // 전체 순차 인덱스 (카테고리 헤더 + 카드)
                return grouped.entries.map((entry) {
                  final category = entry.key;
                  final contracts = entry.value;
                  final headerIndex = animIndex++;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 카테고리 헤더 (순차 등장 애니메이션)
                      AnimatedListItem(
                        index: headerIndex,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(category, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 계약 카드들 (순차 등장 애니메이션)
                      ...contracts.map((c) {
                        final cardIndex = animIndex++;
                        return AnimatedListItem(
                          index: cardIndex,
                          child: _buildContractCard(c),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  );
                });
              }(),
            ],
          ),
        ),
        // 하단: 선택 다운로드 / 전체 다운로드 버튼
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedIds.isEmpty ? _downloadAllContracts : _downloadSelectedContracts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: Text(_selectedIds.isEmpty
                  ? '계약서 전체 다운로드'
                  : '선택 계약서 다운로드 (${_selectedIds.length}건)'),
            ),
          ),
        ),
      ],
    );
  }

  // 전체 계약서 다운로드 (이미지 파일로 순차 다운로드)
  Future<void> _downloadAllContracts() async {
    if (_contracts.isEmpty) return;
    await _downloadContractList(_contracts);
  }

  // 선택한 계약서만 다운로드
  Future<void> _downloadSelectedContracts() async {
    if (_selectedIds.isEmpty) return;
    final selected = _contracts.where((c) => _selectedIds.contains(c['id'])).toList();
    await _downloadContractList(selected);
  }

  // 계약서 목록 다운로드 공통 로직
  Future<void> _downloadContractList(List<Map<String, dynamic>> contracts) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${contracts.length}건의 계약서를 다운로드합니다...')),
    );

    int downloadCount = 0;
    for (final contract in contracts) {
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

  // 계약 카드
  Widget _buildContractCard(Map<String, dynamic> contract) {
    final contractId = contract['id'] as String;
    final isSelected = _selectedIds.contains(contractId);
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

    return GestureDetector(
      onTap: () {
        // 카드 전체 탭으로 선택/해제 토글
        setState(() {
          if (isSelected) {
            _selectedIds.remove(contractId);
          } else {
            _selectedIds.add(contractId);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 체크박스 + 업체명 + 상태 뱃지
            Row(
              children: [
                SizedBox(
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
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(contract['vendorName'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(statusText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 패키지명
            Padding(
              padding: const EdgeInsets.only(left: 28), // 체크박스(20) + 간격(8) 만큼 들여쓰기
              child: Text(contract['productName'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            // 설명
            if ((contract['description'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(contract['description'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
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
            // 상세보기 버튼
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
