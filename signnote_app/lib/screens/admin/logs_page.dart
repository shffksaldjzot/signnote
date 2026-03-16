import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/activity_log_service.dart';
import '../../services/user_service.dart';

// ============================================
// 활동 로그 페이지 (Logs Page)
//
// 개선 사항:
// - B-33: 사용자 이름 표시 (userId → 실제 이름)
// - B-34: 날짜 범위 필터 (DateRangePicker)
// - B-35: 검색 기능 (상세 내용 텍스트 검색)
// ============================================

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final ActivityLogService _logService = ActivityLogService();
  final UserService _userService = UserService();
  final _dateFormat = DateFormat('MM/dd HH:mm:ss');

  bool _isLoading = true;
  List<dynamic> _logs = [];
  String? _selectedAction;

  // B-33: userId → 사용자 이름 매핑
  final Map<String, String> _userNameMap = {};

  // B-34: 날짜 범위 필터
  DateTimeRange? _dateRange;

  // B-35: 검색어
  String _searchQuery = '';

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
    _loadAll();
  }

  // 로그 + 사용자 이름 매핑 로드
  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    // B-33: 전체 사용자 이름 매핑 구축
    if (_userNameMap.isEmpty) {
      for (final role in ['VENDOR', 'ORGANIZER', 'CUSTOMER', 'ADMIN']) {
        final result = await _userService.getUsers(role: role);
        if (result['success'] == true) {
          for (final u in (result['users'] ?? [])) {
            final id = u['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              _userNameMap[id] = u['name']?.toString() ?? '이름 없음';
            }
          }
        }
      }
    }

    await _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    final result = await _logService.getLogs(
      action: _selectedAction,
      limit: 500,
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

  // 필터링된 로그
  List<dynamic> get _filteredLogs {
    var result = _logs.toList();

    // B-34: 날짜 범위 필터
    if (_dateRange != null) {
      result = result.where((log) {
        try {
          final date = DateTime.parse(log['createdAt'].toString());
          return date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
                 date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        } catch (_) { return false; }
      }).toList();
    }

    // B-35: 검색어 필터
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((log) {
        final detail = (log['detail'] ?? '').toString().toLowerCase();
        final userId = log['userId']?.toString() ?? '';
        final userName = _userNameMap[userId]?.toLowerCase() ?? '';
        return detail.contains(query) || userName.contains(query);
      }).toList();
    }

    return result;
  }

  // B-34: 날짜 범위 선택
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;
    final isCompact = MediaQuery.of(context).size.width < 1024;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 새로고침
          Row(
            children: [
              const Text('활동 로그', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_dateRange != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(
                      '${DateFormat('MM.dd').format(_dateRange!.start)} ~ ${DateFormat('MM.dd').format(_dateRange!.end)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _dateRange = null),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              IconButton(onPressed: _loadLogs, icon: const Icon(Icons.refresh), tooltip: '새로고침'),
            ],
          ),
          const SizedBox(height: 8),
          Text('${logs.length}건', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 16),

          // 필터 바
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 행동 종류 필터
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
                    onChanged: (value) { _selectedAction = value; _loadLogs(); },
                  ),
                ),
                // B-34: 날짜 범위
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _dateRange != null
                        ? '${DateFormat('yyyy.MM.dd').format(_dateRange!.start)} ~ ${DateFormat('yyyy.MM.dd').format(_dateRange!.end)}'
                        : '기간 선택',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                // B-35: 검색
                SizedBox(
                  width: isCompact ? double.infinity : 300,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '사용자명, 상세 내용 검색',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 로그 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history, size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty || _dateRange != null
                                  ? '검색 결과가 없습니다' : '기록된 활동이 없습니다',
                              style: const TextStyle(color: AppColors.textHint),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                        ),
                        child: ListView.separated(
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final action = log['action']?.toString() ?? '';
                            final info = _actionInfo[action];
                            final actionName = (info?['name'] as String?) ?? action;
                            final icon = (info?['icon'] as IconData?) ?? Icons.circle;
                            final color = (info?['color'] as Color?) ?? Colors.grey;

                            String time = '';
                            try { time = _dateFormat.format(DateTime.parse(log['createdAt'])); } catch (_) {}

                            // B-33: 사용자 이름
                            final userId = log['userId']?.toString() ?? '';
                            final userName = _userNameMap[userId] ?? '알 수 없음';

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: color.withValues(alpha: 0.1),
                                child: Icon(icon, color: color, size: 18),
                              ),
                              title: Row(
                                children: [
                                  Text(actionName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                                  const SizedBox(width: 8),
                                  // B-33: 사용자 이름 뱃지
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(userName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                log['detail'] ?? '-',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
