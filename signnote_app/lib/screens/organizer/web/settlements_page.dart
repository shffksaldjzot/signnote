import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../services/settlement_service.dart';

// ============================================
// 정산 관리 페이지 (Settlements Page)
//
// 구조:
// ┌─ 상태 탭 ──────────────────────────────────┐
// | [전체]  [대기]  [지급완료]  [정산완료]         |
// └────────────────────────────────────────────┘
//
// ┌─ 정산 테이블 ──────────────────────────────┐
// | 업체명 | 상품명 | 결제액 | 수수료 | 지급액 | 상태 | 지급 |
// └────────────────────────────────────────────┘
// ============================================

class SettlementsPage extends StatefulWidget {
  const SettlementsPage({super.key});

  @override
  State<SettlementsPage> createState() => _SettlementsPageState();
}

class _SettlementsPageState extends State<SettlementsPage> {
  final SettlementService _settlementService = SettlementService();
  final _priceFormat = NumberFormat('#,###', 'ko_KR');

  bool _isLoading = true;
  List<dynamic> _settlements = [];
  String? _selectedStatus;

  // 상태별 한글 이름
  static const _statusNames = {
    'PENDING': '대기',
    'TRANSFERRED': '지급완료',
    'COMPLETED': '정산완료',
  };

  // 상태별 색상
  static const _statusColors = {
    'PENDING': Colors.orange,
    'TRANSFERRED': Colors.blue,
    'COMPLETED': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _loadSettlements();
  }

  Future<void> _loadSettlements() async {
    setState(() => _isLoading = true);

    final result = await _settlementService.getAllSettlements(status: _selectedStatus);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _settlements = result['settlements'] ?? [];
        }
      });
    }
  }

  // 지급 처리
  Future<void> _transfer(String id) async {
    final result = await _settlementService.transfer(id);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지급 처리되었습니다.')),
      );
      _loadSettlements();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '지급 처리 실패')),
      );
    }
  }

  // 완료 처리
  Future<void> _complete(String id) async {
    final result = await _settlementService.complete(id);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정산 완료 처리되었습니다.')),
      );
      _loadSettlements();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '완료 처리 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 합계 계산
    final totalAmount = _settlements.fold<int>(0, (sum, s) => sum + ((s['amount'] ?? 0) as int));
    final totalFee = _settlements.fold<int>(0, (sum, s) => sum + ((s['fee'] ?? 0) as int));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('정산 관리', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '총 ${_settlements.length}건 · 지급액 합계 ${_priceFormat.format(totalAmount)}원 · 수수료 합계 ${_priceFormat.format(totalFee)}원',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),

          // 상태 탭
          _buildStatusTabs(),
          const SizedBox(height: 16),

          // 테이블
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _settlements.isEmpty
                    ? const Center(child: Text('정산 내역이 없습니다'))
                    : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          _buildTab(null, '전체'),
          const SizedBox(width: 8),
          _buildTab('PENDING', '대기'),
          const SizedBox(width: 8),
          _buildTab('TRANSFERRED', '지급완료'),
          const SizedBox(width: 8),
          _buildTab('COMPLETED', '정산완료'),
        ],
      ),
    );
  }

  Widget _buildTab(String? status, String label) {
    final isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () {
        setState(() => _selectedStatus = status);
        _loadSettlements();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('고객명', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('상품명', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('결제액', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('수수료', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('지급액', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('처리', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _settlements.map<DataRow>((s) {
            final contract = s['contract'] ?? {};
            final customer = contract['customer'] ?? {};
            final product = contract['product'] ?? {};
            final status = s['status'] ?? 'PENDING';
            final statusName = _statusNames[status] ?? status;
            final statusColor = _statusColors[status] ?? Colors.grey;
            final depositAmount = contract['depositAmount'] ?? 0;

            return DataRow(cells: [
              DataCell(Text(customer['name'] ?? '-')),
              DataCell(Text(product['name'] ?? '-')),
              DataCell(Text('${_priceFormat.format(depositAmount)}원')),
              DataCell(Text('${_priceFormat.format(s['fee'] ?? 0)}원', style: TextStyle(color: Colors.grey[600]))),
              DataCell(Text('${_priceFormat.format(s['amount'] ?? 0)}원',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
              DataCell(_buildStatusBadge(statusName, statusColor)),
              DataCell(_buildActionButton(s['id'], status)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButton(String id, String status) {
    if (status == 'PENDING') {
      return TextButton(
        onPressed: () => _transfer(id),
        child: const Text('지급', style: TextStyle(color: AppColors.primary)),
      );
    }
    if (status == 'TRANSFERRED') {
      return TextButton(
        onPressed: () => _complete(id),
        child: const Text('완료', style: TextStyle(color: Colors.green)),
      );
    }
    return const Text('-', style: TextStyle(color: Colors.grey));
  }
}
