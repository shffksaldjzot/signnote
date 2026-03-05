import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/app_tab_bar.dart';
import '../../widgets/common/app_button.dart';
import '../../services/product_service.dart';
import '../../utils/number_formatter.dart';
import 'product_add_screen.dart';

// ============================================
// 주관사용 행사 관리 화면
//
// 디자인 참고: 4.주관사용-품목 상세.jpg
// - 상단: ← 행사명 헤더
// - 참여 코드 표시 + 복사 버튼
// - "판매 품목 리스트 >" + "총 N 품목"
// - 아코디언(접기/펼치기) 품목 목록
//   - 펼치면: 협력 업체 / 수수료 / 참가비 / 단가표
//   - 각 필드 옆 연필아이콘 → 인라인 수정
// - 하단: "품목 추가하기" 버튼 + 3탭 네비게이션
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
  final int _currentTabIndex = 0;
  // API에서 가져온 전체 상품 목록
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;

  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _loadProducts();
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

          // "판매 품목 리스트 >" + "총 N 품목"
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      '판매 품목 리스트',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                // 총 품목 수
                Text(
                  '총 ${_products.length} 품목',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 아코디언 품목 목록
          Expanded(child: _buildBody()),
        ],
      ),
      // 하단: "품목 추가하기" 버튼 + 탭바
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: AppButton.black(
              text: '품목 추가하기',
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => OrganizerProductAddScreen(
                      eventId: widget.eventId,
                    ),
                  ),
                );
                if (result == true) _loadProducts();
              },
            ),
          ),
          AppTabBar.organizer(
            currentIndex: _currentTabIndex,
            onTap: _onTabChanged,
          ),
        ],
      ),
    );
  }

  // 본문: 로딩 / 에러 / 아코디언 품목 목록
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
            Text('등록된 품목이 없습니다',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // 아코디언(ExpansionTile) 형태로 품목 표시
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: _products.map((product) => _buildAccordionItem(product)).toList(),
    );
  }

  // 아코디언 품목 아이템 (디자인 가이드 4.주관사용-품목 상세)
  Widget _buildAccordionItem(Map<String, dynamic> product) {
    final name = product['name'] ?? '';
    final vendorName = product['vendorName'] as String? ?? '';
    final fee = product['participationFee'] as int? ?? 0;
    final rate = product['commissionRate'];
    final ratePercent = rate is num ? (rate * 100).toStringAsFixed(0) : '0';
    final formattedFee = NumberFormat('#,###').format(fee);
    // 협력업체가 선점했는지 여부
    final hasVendor = vendorName.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        // 품목명 + ? 아이콘
        title: Row(
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.help_outline, size: 16, color: AppColors.textSecondary),
          ],
        ),
        // 접힌 상태에서도 협력업체명 표시
        subtitle: hasVendor
            ? Text(
                vendorName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            : const Text(
                '업체 미배정',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontStyle: FontStyle.italic,
                ),
              ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 협력 업체
          _buildDetailRow(
            label: '협력 업체',
            value: hasVendor ? vendorName : '미배정',
            onEdit: () => _editField(product, '협력 업체', 'vendorName', vendorName),
          ),
          const SizedBox(height: 10),
          // 수수료
          _buildDetailRow(
            label: '수수료',
            value: '$ratePercent%',
            onEdit: () => _editField(product, '수수료', 'commissionRate', ratePercent),
          ),
          const SizedBox(height: 10),
          // 참가비
          _buildDetailRow(
            label: '참가비',
            value: '$formattedFee원',
            onEdit: () => _editField(product, '참가비', 'participationFee', fee.toString()),
          ),
          const SizedBox(height: 10),
          // 단가표 상세보기
          Row(
            children: [
              const SizedBox(width: 80, child: Text('단가표', style: TextStyle(fontSize: 14, color: AppColors.textPrimary))),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // 단가표 상세보기 (추후 구현)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('단가표 상세보기는 준비 중입니다')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('상세보기', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 상세 정보 한 줄 (라벨 + 값 + 연필 아이콘)
  Widget _buildDetailRow({
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        // 라벨 (고정 너비)
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        // 값 (회색 배경 박스)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 연필 아이콘
        GestureDetector(
          onTap: onEdit,
          child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // 필드 인라인 수정 다이얼로그
  void _editField(
    Map<String, dynamic> product,
    String fieldLabel,
    String fieldKey,
    String currentValue,
  ) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('$fieldLabel 수정', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.right,
          keyboardType: fieldKey == 'vendorName'
              ? TextInputType.text
              : TextInputType.number,
          decoration: InputDecoration(
            hintText: '$fieldLabel 입력',
            suffixText: fieldKey == 'commissionRate'
                ? '%'
                : fieldKey == 'participationFee'
                    ? '원'
                    : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateProductField(product, fieldKey, controller.text);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // 서버에 필드 업데이트 요청
  Future<void> _updateProductField(
    Map<String, dynamic> product,
    String fieldKey,
    String newValue,
  ) async {
    final productId = product['id'].toString();
    Map<String, dynamic> updateData = {};

    if (fieldKey == 'vendorName') {
      updateData['vendorName'] = newValue;
    } else if (fieldKey == 'commissionRate') {
      // % → 소수 변환 (예: 20 → 0.2)
      final percent = double.tryParse(newValue) ?? 0;
      updateData['commissionRate'] = percent / 100;
    } else if (fieldKey == 'participationFee') {
      updateData['participationFee'] = parseCommaNumber(newValue);
    }

    final result = await _productService.updateProduct(productId, updateData);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정되었습니다')),
      );
      _loadProducts(); // 목록 새로고침
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '수정에 실패했습니다')),
      );
    }
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
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
