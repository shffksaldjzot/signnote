import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import 'package:intl/intl.dart';
import '../../services/product_service.dart';
import 'product_add_screen.dart';

// ============================================
// 주관사용 행사 관리 화면
//
// 디자인 참고: 14.주관사용-행사 상세.jpg
// - 상단: ← 행사명 헤더
// - 참여 코드 표시 + 복사 버튼
// - "전체 품목 리스트 >" + 타입 뱃지
// - 카테고리별 상품 목록 (수정 아이콘 포함)
// - 하단: 3탭 네비게이션
//
// ⚠️ 사용자 요청: 참여 코드 생성/관리 기능 포함
// ============================================

class OrganizerEventManageScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String? entryCode;

  const OrganizerEventManageScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.entryCode,
  });

  @override
  State<OrganizerEventManageScreen> createState() =>
      _OrganizerEventManageScreenState();
}

class _OrganizerEventManageScreenState
    extends State<OrganizerEventManageScreen> {
  int _currentTabIndex = 0;
  // API에서 가져온 전체 상품 목록
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;

  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _loadProducts(); // 화면 열릴 때 상품 목록 불러오기
  }

  // 서버에서 행사별 상품 목록 가져오기
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _productService.getProductsByEvent(widget.eventId);

    if (!mounted) return;

    if (result['success'] == true) {
      final List products = result['products'] ?? [];
      setState(() {
        _products = products.map<Map<String, dynamic>>((p) {
          return {
            'id': p['id']?.toString() ?? '',
            'category': p['category'] ?? '기타',
            'vendorName': p['vendorName'] ?? '',
            'name': p['name'] ?? '상품명 없음',
            'description': p['description'] ?? '',
            'price': p['price'] ?? 0,
            'imageUrl': p['image'],
            'participationFee': p['participationFee'] ?? 0,
            'commissionRate': p['commissionRate'] ?? 0,
          };
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? '상품 목록을 불러올 수 없습니다';
        _isLoading = false;
      });
    }
  }

  // 카테고리별로 그룹핑
  Map<String, List<Map<String, dynamic>>> get _groupedProducts {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final product in _products) {
      final category = product['category'] as String;
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(product);
    }
    return grouped;
  }

  // 탭 클릭 시 화면 이동
  void _onTabChanged(int index) {
    if (index == _currentTabIndex) return;
    switch (index) {
      case 0: // 홈 → 주관사 홈으로 돌아가기
        Navigator.of(context).pop();
        break;
      case 1: // 계약함 (아직 주관사 모바일 계약 화면 없음)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계약함은 준비 중입니다')),
        );
        break;
      case 2: // 마이페이지
        context.push(AppRoutes.mypage, extra: 'ORGANIZER');
        break;
    }
  }

  // 참여 코드를 클립보드에 복사
  void _copyEntryCode() {
    if (widget.entryCode != null) {
      Clipboard.setData(ClipboardData(text: widget.entryCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참여 코드가 복사되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(title: widget.eventTitle),
      body: Column(
        children: [
          // 참여 코드 카드
          if (widget.entryCode != null) _buildEntryCodeCard(),

          // "전체 품목 리스트 >" + 품목 추가 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      '전체 품목 리스트',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                // 품목 추가 버튼
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => OrganizerProductAddScreen(
                          eventId: widget.eventId,
                        ),
                      ),
                    );
                    // 품목 추가 성공 시 목록 새로고침
                    if (result == true) _loadProducts();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: AppColors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '품목 추가',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 상품 목록 (카테고리별)
          Expanded(child: _buildBody()),
        ],
      ),
      // 하단 탭바
      bottomNavigationBar: AppTabBar.organizer(
        currentIndex: _currentTabIndex,
        onTap: _onTabChanged,
      ),
    );
  }

  // 본문: 로딩 / 에러 / 상품 목록 분기
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
            TextButton(onPressed: _loadProducts, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('등록된 품목이 없습니다', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: _groupedProducts.entries.map((entry) {
        final category = entry.key;
        final products = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // 카테고리 헤더
            Row(
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.help_outline,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
            // 주관사용 품목 카드 (이미지 + 품목명 + 참가비 + 수수료)
            ...products.map((product) => _buildOrganizerProductCard(product)),
            const Divider(height: 24),
          ],
        );
      }).toList(),
    );
  }

  // 주관사용 품목 카드 (이미지 + 품목명 + 참가비 + 수수료 + 수정아이콘)
  Widget _buildOrganizerProductCard(Map<String, dynamic> product) {
    final fee = product['participationFee'] as int? ?? 0;
    final rate = product['commissionRate'];
    final ratePercent = rate is num ? (rate * 100).toStringAsFixed(0) : '0';
    final formattedFee = NumberFormat('#,###').format(fee);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽: 썸네일 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: AppColors.background,
              child: product['imageUrl'] != null
                  ? Image.network(product['imageUrl'], fit: BoxFit.cover)
                  : const Icon(Icons.image_outlined, color: AppColors.textHint),
            ),
          ),
          const SizedBox(width: 12),
          // 오른쪽: 품목 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 품목명
                Text(
                  product['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                // 참가비
                Text(
                  '참가비 : $formattedFee원',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                // 수수료
                Text(
                  '수수료 : $ratePercent%',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 수정 아이콘
          GestureDetector(
            onTap: () => _editProduct(product),
            child: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 품목 수정 (주관사가 품목명/참가비/수수료 수정)
  void _editProduct(Map<String, dynamic> product) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrganizerProductAddScreen(
          eventId: widget.eventId,
          product: product, // 기존 데이터 전달 (수정 모드)
        ),
      ),
    );
    if (result == true) _loadProducts();
  }

  // 참여 코드 표시 카드
  Widget _buildEntryCodeCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.key, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          // 코드 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '참여 코드',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.entryCode!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // 복사 버튼
          GestureDetector(
            onTap: _copyEntryCode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, color: AppColors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    '복사',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
