import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/activity_log_service.dart';

// ============================================
// 활동 로그 페이지 (Logs Page)
//
// 고객/업체/주관사의 모든 행동 기록을 보여주는 페이지
//
// 구조:
// ┌─ 필터 ─────────────────────────────────────┐
// | [전체 ▼ 행동 종류]        [새로고침]          |
// └────────────────────────────────────────────┘
//
// ┌─ 로그 목록 ─────────────────────────────────┐
// | 시간 | 행동 | 상세 | 사용자ID               |
// └────────────────────────────────────────────┘
// ============================================

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final ActivityLogService _logService = ActivityLogService();
  final _dateFormat = DateFormat('MM/dd HH:mm:ss');

  bool _isLoading = true;
  List<dynamic> _logs = [];
  String? _selectedAction;

  // 행동 종류별 한글 이름 + 아이콘
  static const _actionInfo = {
    'LOGIN': {'name': '로그인', 'icon': Icons.login, 'color': Colors.blue},
    'REGISTER': {'name': '회원가입', 'icon': Icons.person_add, 'color': Colors.green},
    'EVENT_CREATE': {'name': '행사 생성', 'icon': Icons.event, 'color': Colors.purple},
    'EVENT_UPDATE': {'name': '행사 수정', 'icon': Icons.edit, 'color': Colors.purple},
    'EVENT_ENTER': {'name': '행사 입장', 'icon': Icons.door_front_door, 'color': Colors.teal},
    'PRODUCT_CREATE': {'name': '상품 등록', 'icon': Icons.add_box, 'color': Colors.orange},
    'PRODUCT_UPDATE': {'name': '상품 수정', 'icon': Icons.edit_note, 'color': Colors.orange},
    'CART_ADD': {'name': '장바구니 추가', 'icon': Icons.add_shopping_cart, 'color': Colors.indigo},
    'CART_REMOVE': {'name': '장바구니 삭제', 'icon': Icons.remove_shopping_cart, 'color': Colors.grey},
    'CONTRACT_CREATE': {'name': '계약 생성', 'icon': Icons.description, 'color': Colors.blue},
    'CONTRACT_CANCEL_REQUEST': {'name': '취소 요청', 'icon': Icons.warning, 'color': Colors.orange},
    'CONTRACT_CANCEL_APPROVE': {'name': '취소 승인', 'icon': Icons.check_circle, 'color': Colors.red},
    'CONTRACT_CANCEL_REJECT': {'name': '취소 거부', 'icon': Icons.block, 'color': Colors.grey},
    'PAYMENT_CREATE': {'name': '결제', 'icon': Icons.payment, 'color': Colors.green},
    'PAYMENT_REFUND': {'name': '환불', 'icon': Icons.money_off, 'color': Colors.red},
    'SETTLEMENT_TRANSFER': {'name': '정산 지급', 'icon': Icons.send, 'color': Colors.blue},
    'SETTLEMENT_COMPLETE': {'name': '정산 완료', 'icon': Icons.check, 'color': Colors.green},
  };

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    final result = await _logService.getLogs(
      action: _selectedAction,
      limit: 200,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _logs = result['logs'] ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('활동 로그', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                onPressed: _loadLogs,
                icon: const Icon(Icons.refresh),
                tooltip: '새로고침',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('최근 ${_logs.length}건', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 20),

          // 행동 종류 필터
          _buildFilter(),
          const SizedBox(height: 16),

          // 로그 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('기록된 활동이 없습니다'))
                    : _buildLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              value: _selectedAction,
              decoration: const InputDecoration(
                labelText: '행동 종류',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('전체')),
                ..._actionInfo.entries.map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value['name'] as String),
                )),
              ],
              onChanged: (value) {
                _selectedAction = value;
                _loadLogs();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: ListView.separated(
        itemCount: _logs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final log = _logs[index];
          final action = log['action']?.toString() ?? '';
          final info = _actionInfo[action];
          final actionName = (info?['name'] as String?) ?? action;
          final icon = (info?['icon'] as IconData?) ?? Icons.circle;
          final color = (info?['color'] as Color?) ?? Colors.grey;

          String time = '';
          try {
            time = _dateFormat.format(DateTime.parse(log['createdAt']));
          } catch (_) {}

          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 18),
            ),
            title: Text(actionName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            subtitle: Text(
              log['detail'] ?? '-',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                if (log['userId'] != null)
                  Text(
                    '${log['userId'].toString().substring(0, 8)}...',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
